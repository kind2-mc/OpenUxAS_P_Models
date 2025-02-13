# P models

1. [P Primer](#p-primer)
2. [Development Notes](#development-notes)

## P Primer

This is a brief introduction to the P programming language, for a more complete
guide please see the [official manual](https://p-org.github.io/P/manualoutline/).

[P](https://github.com/p-org/P) is a high level, asynchronous, state machine
oriented language. A P program is a collection of concurrently running state
machines who communicate with each other by sending messages.

### Messages

New message types can be declared. There are two kinds of messages, those with
and without payloads. Their declarations look like:
```P
event eStartTimer;
event eComputationComplete : tId;
```
In this example `eStartTimer` is a message with no payload while
`eComputationComplete` has a payload of type `tId`.

Messages are sent using the send keyword and take two forms dependent on if
there is a needed payload.

```P
send machine, message;
send machine, message, payload;
```

Similar to sending a message can be announced. Announcing a message broadcasts
it to all observers. Observers are how specifications are modeled in `P`.
Announced messages are used to help verify properties about the system but are
not used to drive behavior. They play a similar role as shadow variables in
kind2. The syntax is basically the same as `sending`:

```P
announce message;
announce message, payload;
```

##### Send Semantics

Messages in `P` are always received. Machines receive one message at a time. If
machine A sends machine B two messages machine B is guaranteed to receive those
messages in order. Beyond this guarantee there is no guarantees on the order
messages are received. If you wish to model a system with network failure and
arbitrary order this has to be modeled explicitly.

### Machines

A machines declaration is comprised of variable and state declarations. For example:

```P
machine SensorManager {

    var bus: Bus;

    start state Init {
        ...
    }

    state WaitForComputationRequest {
        ...
    }
}
```

Declares a state machine `SensorManager` with one variable `bus` of type `Bus`
and with two states `Init` and `WaitForComputationRequest`. `Init` is marked as
the starting state with the `start` keyword. The starting state is the state
which any new machine of this type will start in.

States have optional entry points which are declared with the `entry` keyword.
For example

```P
    start state Init {
        entry (b: Bus) {
            bus = b;
            send bus, eSubscribe, this;
        }
    }
```

says when the `Init` state is entered set `bus` to `b` and send an `eSubscribe`
message to the `bus` (more on that in a minute).

States are switched to using the `goto` keyword, if the entry point of the
state takes arguments those have to be supplied. For example `goto Idle;` will
cause a transition to the `Idle` state and `goto Pending, 10;` transition to
the `Pending` state while giving the entry point `10` as an argument.

States listen to messages using the `on` keyword, these will trigger
the code when a message of that type is received. For example:

```P
on eMessage do (in_msg : tMessage) {
    var payload : tTaskMsg;
    if(in_msg.kind == Task) {
        HandleTaskMsg(in_msg.payload);
    }
}
```

will trigger when the machine receives an `eMessage`. If the message has no
payload the argument list can be omitted.

If a state does not care about a message it has two choices. First `defer
event_type;` will ignore the message but keep it in the queue. Alternatively
`ignore event_type;` will pop the event off the queue but do nothing with it.

### Testing

State machines are used to check properties of the system. These special state
machines are called observers and can be declared with the `spec` keyword in
place of the `machine` keyword. There are a couple of limitations on observers:
1. They can have no side effects. They cannot `send`, `announce`, or create new
   machines.
2. They are global. There is only one copy of each monitor running at a time.

In addition to these restrictions observers can have `hot` states. A `hot`
state is used to model liveness properties. If an execution ends and an
observer is in a `hot` state this constitutes an error.

### Broadcast

As sending messages in `P` is one-to-one and messages in OpenUxAS is
many-to-many this repository explicitly models the network communication. This
is modeled using the `Bus` machine defined in `openuxas/Bus.p`. As `P` lacks
support for discriminated types this repository wraps every message in
the type `tMessage` to simulate them:
```P
type tMessage = (
    kind    : tMsgKind,
    sender  : machine,
    payload : data
);
```
This results every state machine listening for `tMessage`s and then manually
casting the payload data to the correct type. For example:
```P
start state Idle {
    on eMessage do (msg: tMessage) {
        if (msg.kind == EntityState) {
            HandleEntityStateMsg(msg.payload as tEntityStateMsg);
        }
        else if (msg.kind == UniqueAutomationRequest) {
            HandleUniqueAutomationRequestMsg(msg.payload as tUniqueAutomationRequestMsg);
        }
    }
}
```

## Development Notes

### Development Environment

The only tool needed is [P](https://github.com/p-org/P). If you happen to be on
linux and have [nix](https://nixos.org) installed `nix develop` will drop you
into a shell with all your needed dependencies.

### Compiling the model

To compile the model from the command line run the command

```
p compile
```

### Listing test cases

To get a list of test cases run

```
p check --list-tests
```

### Running tests cases

To run the test case `tcName` from the command line run the command

```
p check -tc tcName -s 100
```

*NOTE:* this does not recompile the project, if changes have been made you
probably want to recompile
