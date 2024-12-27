##############################################
# Text2Piper.pm
#
# FHEM module for text-to-speech using Piper TTS server
# Connects to a remote Piper server over TCP/IP
##############################################

package main;                    # Define this code as part of the main package

# Enable strict Perl practices for better code quality and error catching
use strict;                     # Enforce strict variable declarations
use warnings;                   # Enable warning messages
use Blocking;                   # For non-blocking operations in FHEM
use IO::Socket::INET;           # For TCP/IP networking functionality

###################################
# Module Initialization
# Called by FHEM when loading the module
###################################
sub Text2Piper_Initialize($) {
    my ($hash) = @_;           # Get the hash reference passed by FHEM
    
    # Register callback functions for FHEM events
    $hash->{DefFn}     = "Text2Piper_Define";    # Called when device is defined
    $hash->{SetFn}     = "Text2Piper_Set";       # Called for set commands
    $hash->{UndefFn}   = "Text2Piper_Undefine";  # Called when device is undefined
    
    # Define available attributes
    $hash->{AttrList}  = "disable:0,1 "          # Allow enabling/disabling the device
                         .$readingFnAttributes;    # Add standard FHEM reading attributes
}

###################################
# Define Function
# Called when creating a new device instance
# Syntax: define <name> Text2Piper <host> <port>
###################################
sub Text2Piper_Define($$) {
    my ($hash, $def) = @_;                     # Get device hash and definition string
    my @a = split("[ \t]+", $def);            # Split definition on whitespace
    
    # Verify correct number of parameters
    if(int(@a) < 4) {                         # Need name, type, host, port
        return "wrong syntax: define <name> Text2Piper <host> <port>";
    }
    
    # Store connection details in hash
    $hash->{HOST} = $a[2];                    # Server hostname or IP
    $hash->{PORT} = $a[3];                    # Server port
    $hash->{STATE} = "Initialized";           # Set initial device state
    
    return undef;                             # Return success
}

###################################
# Undefine Function
# Called when removing a device instance
###################################
sub Text2Piper_Undefine($$) {
    my ($hash, $arg) = @_;                    # Get device hash and arguments
    
    # Clean up any running processes
    BlockingKill($hash->{helper}{RUNNING_PID}) 
        if(defined($hash->{helper}{RUNNING_PID}));
    
    return undef;                             # Return success
}

###################################
# Set Function
# Handles set commands from FHEM
# Currently supports: set <name> tts <text>
###################################
sub Text2Piper_Set($@) {
    my ($hash, @a) = @_;                      # Get device hash and arguments array
    
    # Check for minimum parameters
    return "no set argument specified" if(int(@a) < 2);
    
    my $cmd = $a[1];                          # Get command (should be 'tts')
    
    # Validate command
    if($cmd ne "tts") {
        return "Unknown argument $cmd, choose one of tts";
    }
    
    # Check if device is disabled
    return undef if(AttrVal($hash->{NAME}, "disable", "0") eq "1");
    
    # Remove device name and command from arguments
    shift(@a);                                # Remove device name
    shift(@a);                                # Remove 'tts' command
    
    # Join remaining arguments into text to speak
    my $text = join(" ", @a);
    
    # Start non-blocking operation
    $hash->{helper}{RUNNING_PID} = BlockingCall(
        "Text2Piper_DoIt",                    # Function to execute
        $hash->{NAME}."|".$text,             # Parameters: name and text
        "Text2Piper_Done",                    # Callback when complete
        60,                                   # Timeout in seconds
        "Text2Piper_AbortFn",                 # Function to call on timeout
        $hash                                 # Device hash
    );
    
    return undef;                             # Return success
}

###################################
# DoIt Function
# Performs actual network communication
# Runs in a separate thread to avoid blocking FHEM
###################################
sub Text2Piper_DoIt($) {
    my ($string) = @_;                        # Get parameter string
    my ($name, $text) = split("\\|", $string); # Split into device name and text
    my $hash = $defs{$name};                  # Get device hash
    
    # Create TCP socket connection to server
    my $socket = IO::Socket::INET->new(
        PeerHost => $hash->{HOST},            # Server hostname/IP
        PeerPort => $hash->{PORT},            # Server port
        Proto    => 'tcp'                     # Use TCP protocol
    ) or return "$name|Error: $!";            # Return error if connection fails
    
    # Send text to server
    print $socket $text;
    
    # Get server response
    my $response = <$socket>;
    
    # Clean up
    close($socket);
    
    return "$name|$response";                 # Return result to callback
}

###################################
# Done Function
# Called when blocking operation completes
###################################
sub Text2Piper_Done($) {
    my ($string) = @_;                        # Get result string
    my ($name, $result) = split("\\|", $string); # Split into name and result
    my $hash = $defs{$name};                  # Get device hash
    
    # Clean up process ID
    delete($hash->{helper}{RUNNING_PID});
    
    # Log any errors
    if($result =~ /^Error/) {
        Log3 $name, 2, "Text2Piper: $result";
    }
}

###################################
# Abort Function
# Called if blocking operation times out
###################################
sub Text2Piper_AbortFn($) {
    my ($hash) = @_;                          # Get device hash
    
    # Clean up process ID
    delete($hash->{helper}{RUNNING_PID});
    
    # Log abort event
    Log3 $hash->{NAME}, 2, "Text2Piper: BlockingCall for ".$hash->{NAME}." was aborted";
}

1;                                            # Return true (required for Perl modules)

# Module documentation
=pod
=begin html_DE 
<a name="Text2Piper"></a>
<h3>Text2Piper</h3> 
<ul>
  <br>
  <a name="Text2Piperdefine"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; Text2Piper &lt;host&gt; &lt;port&gt;</code>
    <br>
    <br>
    Defines a Text2Piper device that connects to a Piper TTS server.
    <br>
    Example: define tts Text2Piper 192.168.1.100 8765
  </ul>
</ul>

<a name="Text2Piperset"></a>
<b>Set</b> 
<ul>
  <code>set &lt;name&gt; tts &lt;text&gt;</code>
  <br>
  Sends text to the Piper server for text-to-speech conversion.
</ul><br> 

<a name="Text2Piperattr"></a>
<b>Attributes</b>
<ul>
  <li><a>disable</a><br>
    If this attribute is activated, the text-to-speech output will be disabled.<br><br>
    Possible values: 0 => not disabled , 1 => disabled<br>
    Default Value is 0 (not disabled)<br><br> 
  </li>

  <li><a href="#readingFnAttributes">readingFnAttributes</a></li><br>
</ul>

=end html_DE
=cut
