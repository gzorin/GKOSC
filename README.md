As of May 2012, this is very much a work-in-progress, developed quickly to facilitate communication between two iOS devices.

This library implements very basic remote procedure calls between Objective-C objects, encoded as OpenSoundControl messages. Included is the capability to transport messages with UDP (using the UDPEcho example distributed on Apple's developer site) and with iOS's GameKit framework.

The library furnishes OSC client programs with an Objective-C message invocation-style interface to sending OSC messages. On the server side, OSC message handling is implemented as Objective-C methods.

Please see the demo/ directory to view some simple examples. In general, programs that use this library should associate OSC addresses ("/foo") and argument format strings ("fff", etc") with Objective-C selectors (@selector(performFooWithX:andY:andZ:)). The OSC argument format string (and not the object method's signature, as this may not be known on the client side) is authoritative about the data that gets serialized.

Currently, only OSC 1.0 is supported.