# LoonE Script

LoonE is a wrapper for containers.

Allows you to build the containers, enter them, move to the work environment, check status of containers, and build with virtual zedx or hardware zedx settings. 

The `--help` flag provides a detailed description of the available options and their usage.

## Example Usage

Building zed service with virtual zedx profile:

```bash
loonE -b --virtual zed
```

Building zed service with hardware zedx profile:

```bash
loonE -b --hardware zed
```

building loone service:

```bash
loonE -b loone
```

Starting loone service:

```bash
loonE -s loone
```

entering loone service container:

```bash
loonE -e loone
```