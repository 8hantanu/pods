# pods 🫛

**Portable On-Demand Sandbox**

This repository defines the `pods` system: a collection of Podman-based
environments for different workflows such as day-to-day development,
deployment, and other task-specific sandboxes.

## Layout

```text
pod-dev/
```

Each pod keeps its own `Containerfile` and helper scripts in its own
folder.

## Pods

- [pod-dev](./pod-dev): day-to-day development pod
