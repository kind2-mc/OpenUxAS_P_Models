# Development Notes

## Development Environment

The only tool needed is [P](https://github.com/p-org/P). If you happen to be on
linux and have [nix](https://nixos.org) installed `nix develop` will drop you
into a shell with all your needed dependencies.

## Compiling the model

To compile the model from the command line run the command

```
p compile
```

## Listing test cases

To get a list of test cases run

```
p check --list-tests
```

## Running tests cases

To run the test case `tcName` from the command line run the command

```
p check -tc tcName -s 100
```

*NOTE:* this does not recompile the project, if changes have been made you
probably want to recompile
