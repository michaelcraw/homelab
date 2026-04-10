# Grafana Alert Queries

All alerts notify a Slack webhook in the #alert channel of a dedicated Homelab workspace.

## CPU Temperature (Fahrenheit)

Alerts when any machine's CPU temperature exceeds 176°F (80°C).

```promql
(max(node_hwmon_temp_celsius{chip=~".*coretemp.*", sensor=~"temp1|temp2"}) * 9/5) + 32
```

Threshold: IS ABOVE 176

## Machine Offline

Alerts when any machine in the fleet stops responding to Prometheus.

```promql
up{job="node"}
```

Threshold: IS BELOW 0.5

## Disk Space Low

Alerts when any root filesystem exceeds 85% used.

```promql
100 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100)
```

Threshold: IS ABOVE 85

## Disk Health (Reallocated Sectors)

Alerts when any drive develops reallocated sectors indicating possible failure.

```promql
smartctl_device_attribute{attribute_name="Reallocated_Sector_Ct"}
```

Threshold: IS ABOVE 100

## High RAM Usage

Alerts when any machine exceeds 90% memory usage.

```promql
100 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100)
```

Threshold: IS ABOVE 90

## Camera Disk - Warning (Primary Drive)

Alerts when the Raspberry Pi's primary camera storage exceeds 75% used.

```promql
100 * (
  1 - (
    node_filesystem_free_bytes{instance="livecam", mountpoint="/mnt/camera", device="/dev/sda"}
    /
    node_filesystem_size_bytes{instance="livecam", mountpoint="/mnt/camera", device="/dev/sda"}
  )
)
```

Threshold: IS ABOVE 75 (with Reduce → Last → Drop Non-numeric Values)

## Camera Disk - Critical (Primary Drive)

Alerts when the Pi's primary camera storage exceeds 90% used.

```promql
100 * (1 - (
  node_filesystem_avail_bytes{instance="livecam",mountpoint="/mnt/camera"}
  /
  node_filesystem_size_bytes{instance="livecam",mountpoint="/mnt/camera"}
))
```

Threshold: IS ABOVE 90

## Camera Disk 2 - Warning (Secondary Drive)

Alerts when the Pi's secondary camera storage exceeds 75% used.

```promql
100 * (1 - (
  node_filesystem_avail_bytes{instance="livecam",mountpoint="/mnt/camera2"}
  /
  node_filesystem_size_bytes{instance="livecam",mountpoint="/mnt/camera2"}
))
```

Threshold: IS ABOVE 75

## Camera Disk 2 - Critical (Secondary Drive)

Alerts when the Pi's secondary camera storage is nearly full (99%).

```promql
100 * (1 - (
  node_filesystem_avail_bytes{instance="livecam",mountpoint="/mnt/camera2"}
  /
  node_filesystem_size_bytes{instance="livecam",mountpoint="/mnt/camera2"}
))
```

Threshold: IS ABOVE 99

## Notes

- Camera storage alerts work in conjunction with the `motion-storage-check.sh` script which automatically rotates recording between the two USB drives when one fills up.
- Most alerts use a Pending period of 1m and Keep firing for 5m to prevent flapping.
- The CPU Temperature query uses `temp1|temp2` to handle different sensor naming across coretemp chips on various machines.
