# pod-dev

Day-to-day development pod for the `pods` system.

## Build

```bash
./pod-dev/build.sh
```

Builds the image, prepares the pod volume, and can optionally generate
or use GitHub SSH credentials for cloning `wiki`, `dots`, and `plug`
during the build. If enabled, the running pod will automatically mount
that same host key.

## Init

```bash
./pod-dev/init.sh
```

Runs the pod on first use and reattaches on later runs.
