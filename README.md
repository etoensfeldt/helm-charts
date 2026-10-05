<div align="center">
  <a href="https://opc-router.com/?utm_source=GitHub&utm_medium=HelmChart&utm_campaign=OpcRouterChart">
    <img src="img/opc_router_logo.png" alt="Logo" >
  </a>
    <br />
    <br />
  <h1 align="center">OPC Router Helm Chart</h1>
  <p align="center">
    OPC Router Helm Chart for the deployment of the OPC Router in a kubernetes cluster.
    <br />
    <a href="https://opc-router.com/?utm_source=GitHub&utm_medium=HelmChart&utm_campaign=OpcRouterChart"><strong>OPC Router</strong></a>
    -
    <a href="https://www.opc-router.com/contact-and-support/?utm_source=GitHub&utm_medium=HelmChart&utm_campaign=OpcRouterChart"><strong>Contact</strong></a>
    <br />
    <br />
  </p>
</div>

# About the chart
## **Contents**
- [About the chart](#about-the-chart)
  - [**Contents**](#contents)
  - [General Information](#general-information)
    - [**What is the helm chart doing?**](#what-is-the-helm-chart-doing)
- [Getting Started](#getting-started)
  - [**Prerequisites**](#prerequisites)
  - [**Installation**](#installation)
  - [**Uninstalling**](#uninstalling)
- [Upgrading](#upgrading)
  - [**Upgrading to 1.0.5**](#upgrading-to-105)
  - [**When the MongoDB pod does not start**](#when-the-mongodb-pod-does-not-start)
  - [**Tools that render the chart without the cluster**](#tools-that-render-the-chart-without-the-cluster)
  - [**Rolling back**](#rolling-back)
  - [**Moving to OPC Router 5.7**](#moving-to-opc-router-57)
- [Configuration](#configuration)
  - [**Parameters**](#parameters)
  - [**Requirements of the OPC Router on Kubernetes**](#requirements-of-the-opc-router-on-kubernetes)
  - [**Storage**](#storage)
  - [**Updates and downtime**](#updates-and-downtime)
  - [**Health probes**](#health-probes)
  - [**Security**](#security)
  - [**WARNING: MongoDB root password and replica key set**](#warning-mongodb-root-password-and-replica-key-set)
  - [**Image versions**](#image-versions)
  - [**Using the `opcrouter/runtime` image**](#using-the-opcrouterruntime-image)
  - [**Managed clusters with admission policies**](#managed-clusters-with-admission-policies)
  - [**Using Ingress or reverse proxies**](#using-ingress-or-reverse-proxies)
  - [**Extra ports, environment variables, volumes and init containers**](#extra-ports-environment-variables-volumes-and-init-containers)
  - [**High availability**](#high-availability)
  - [**Loading a project from a git repository**](#loading-a-project-from-a-git-repository)
  - [**Adding extra environment variables**](#adding-extra-environment-variables)

## General Information

### **What is the helm chart doing?**
- It deploys the OPC Router onto a Kubernetes cluster, as a Deployment with one pod.
- By default it runs the `opcrouter/service` image and deploys a MongoDB next to it (the Bitnami
  MongoDB chart with MongoDB 4.4.15) as the router's database.
- Alternatively it runs the `opcrouter/runtime` image, which carries its own database.
- The router keeps its data on two persistent volumes, see [Storage](#storage).
- Optionally it adds an Ingress, loads a project from a git repository and updates it
  automatically, and probes the router's health.

# Getting Started

## **Prerequisites**
- Kubernetes 1.25 or later. The chart is validated against the API schemas of Kubernetes 1.25,
  1.30 and 1.34.
- Helm 3. `--reset-then-reuse-values` (see [Upgrading](#upgrading)) needs Helm 3.14 or later.
- A default StorageClass, or `claims.inray.storageClassName` and `claims.log.storageClassName`.
- What the router itself needs from the cluster:
  [Requirements of the OPC Router on Kubernetes](#requirements-of-the-opc-router-on-kubernetes).

## **Installation**
[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:
```shell
helm repo add opc-router https://opc-router.github.io/helm-charts
```
If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
<alias>` to see the charts.

To install the chart with the name `my-opcrouter`:
```shell
helm install my-opcrouter opc-router/opc-router \
  --set I_do_accept_the_EULA=true
```
This command installs the OPC Router with standard settings: the `opcrouter/service` image with a
separate MongoDB. Neither the web management nor the MongoDB asks for a login, which is not
recommended beyond a first test, see [Security](#security). Accepting the
[End User License Agreement](https://www.opc-router.com/terms-of-use-and-eula/) by setting
`I_do_accept_the_EULA` to true is required for the OPC Router to run.

To deploy this chart with password authentication for the web management and for the mongodb use this command:
```shell
helm install my-opcrouter opc-router/opc-router \
  --set webManagement.auth.disable=false \
  --set webManagement.auth.initialUser.name=<Your desired initial web management user name>\
  --set webManagement.auth.initialUser.password=<Your desired initial web management user password>\
  --set mongodb.auth.enabled=true \
  --set mongodb.auth.rootPassword=<Your desired mongodb root password> \
  --set mongodb.auth.replicaSetKey=<Your desired mongodb replicaset key> \
  --set I_do_accept_the_EULA=true
```
Keep in mind that the root password and replicaset key can't be changed once set. When leaving the password and/or replicaset key empty when auth is enabled, the chart will autogenerate the missing secret.
MongoDB reads the replica set key as a key file: it needs at least 6 characters, and only letters,
digits, `+`, `/` and `=`. Any other character, a `-` for example, keeps MongoDB from starting.

## **Uninstalling**
The chart with the name `my-opcrouter` can simply be uninstalled by executing:
```shell
helm uninstall my-opcrouter
```
The router's two volume claims are deleted with the release, unless `claims.inray.keepAfterUninstall`
or `claims.log.keepAfterUninstall` is true. The volumes of the bundled MongoDB are not deleted.
When reinstalling the chart under the same name you will have to use the previous mongodb root
password and replica set key, or delete that volume beforehand.

# Upgrading

## **Upgrading to 1.0.5**

Chart 1.0.5 keeps OPC Router 5.3 as the default image and keeps what an existing installation relies
on: the names of its volumes, its pod selector and its database. It changes the following:
- The bundled MongoDB runs `bitnamilegacy/mongodb:4.4.15`. Bitnami has removed its versioned images
  from `docker.io/bitnami`, so earlier chart versions can no longer start a new or rescheduled MongoDB
  pod. MongoDB 4.4.15 opens the data of the 4.4.11 image the earlier versions used.
- An existing release keeps its pod selector. Versions up to 1.0.4 put the chart version into it, so
  every upgrade between them failed with `spec.selector: Invalid value … field is immutable`.
- With the embedded database (`opcrouter/runtime` and `mongodb.deploy=false`) the pod is replaced
  with the strategy `Recreate`, because two pods on one database cannot both start. See
  [Updates and downtime](#updates-and-downtime).
- The router container gets `S6_BEHAVIOUR_IF_STAGE2_FAILS=2`: a container whose startup fails exits,
  and Kubernetes restarts it, instead of running on without answering.
- With the embedded database an init container creates the database's log folder on the log volume;
  a new, empty log volume next to an existing database no longer stops every start.
- The service account gets only the permissions the project auto-update needs, and only then; the
  router pod mounts no API token otherwise.
- A new installation gets volume sizes that fit how the router runs; an existing claim keeps its size.
- New, all off by default: [health probes](#health-probes), extra ports, environment variables,
  volumes and init containers, resources for every container, a project import mode and a rotation
  of the embedded database's log.

Upgrade with the new defaults and the values you set yourself:
```shell
helm repo update
helm upgrade my-opcrouter opc-router/opc-router --version 1.0.5 --reset-then-reuse-values
```
Instead of `--reset-then-reuse-values` you can pass your complete values file with `-f`. Plain
`--reuse-values` keeps the defaults of your old chart version, among them the MongoDB image that no
longer exists, and still reports success; with it, add the new image explicitly:
```shell
helm upgrade my-opcrouter opc-router/opc-router --version 1.0.5 --reuse-values \
  --set mongodb.image.registry=docker.io \
  --set mongodb.image.repository=bitnamilegacy/mongodb \
  --set mongodb.image.tag=4.4.15
```
To preview an upgrade, use `--dry-run=server`: the chart reads the existing Deployment and volume
claims from the cluster, which a client-side dry run cannot.

Releases installed with chart 1.0.0 or 1.0.1 run OPC Router 5.1 or 5.2, unless they set `image.tag`.
The upgrade to 1.0.5 moves them to 5.3; set `image.tag` to stay on your version.

## **When the MongoDB pod does not start**

If the MongoDB pod of a release stays in `ErrImagePull` or `ImagePullBackOff` on
`bitnami/mongodb:4.4.11-debian-10-r12`, the new image alone does not replace it: Kubernetes does not
replace a StatefulSet pod that never became ready. After the upgrade, delete it once:
```shell
kubectl delete pod my-opcrouter-mongodb-0
```
To repair an installation without changing its chart version, give the installed version and the
image, then delete the pod as above:
```shell
helm upgrade my-opcrouter opc-router/opc-router --version <installed version> --reuse-values \
  --set mongodb.image.registry=docker.io \
  --set mongodb.image.repository=bitnamilegacy/mongodb \
  --set mongodb.image.tag=4.4.15
```
The image values belong under `mongodb:`. A values file with a top-level `mongo:` key upgrades without
an error and changes nothing.

## **Tools that render the chart without the cluster**

Tools that render the chart with `helm template` instead of installing it, such as Argo CD, give it no
access to the cluster. The chart then cannot read what it keeps for an existing release:
- **The pod selector.** For a release installed with chart 1.0.4 or earlier, the rendered selector
  differs. Kubernetes refuses that change on the Deployment, and applying it to the Service keeps the
  Service's old labels next to the new ones, so it selects no pod. Delete both once and let the tool
  create them again (`kubectl delete deployment,service my-opcrouter-opc-router`); the volumes stay,
  the router restarts.
- **The size of existing volume claims.** Set `claims.inray.capacity` and `claims.log.capacity` to the
  sizes of your claims (`kubectl get pvc`); the defaults of chart 1.0.4 and earlier were `100M` and
  `1Gi`. Otherwise the tool asks Kubernetes to resize them.

## **Rolling back**

`helm rollback` to 1.0.4 or earlier restores that version's MongoDB image, which no longer exists:
Kubernetes replaces the running MongoDB pod with one that cannot start, and the router loses its
database. If you have to go back, repair it as in
[When the MongoDB pod does not start](#when-the-mongodb-pod-does-not-start) with `--version <that version>`.

## **Moving to OPC Router 5.7**

Chart 1.0.5 still installs OPC Router 5.3 by default. OPC Router 5.7 runs on the bundled MongoDB 4.4.15;
it supports MongoDB from 4.2 on and recommends 6.0 or later, which a later chart version will provide.
To move to 5.7:
```shell
helm upgrade my-opcrouter opc-router/opc-router --version 1.0.5 --reset-then-reuse-values \
  --set image.tag=5.7
```
- **Back up first.** Export the project. With the embedded database, the first start of 5.7 migrates
  the database to MongoDB 8, and the 5.3 image cannot open it afterwards.
- **Project import:** with a project from a git repository, set `project.importMode=overwrite`. The
  default `clear` stops the web management of OPC Router 5.5, 5.6 and 5.7 from starting (a known
  defect), see [Loading a project from a git repository](#loading-a-project-from-a-git-repository).
- With [health probes](#health-probes) enabled, the startup budget covers the migration.

# Configuration

## **Parameters**

### **Global parameters**

These are read by the bundled MongoDB chart only.

| Name                       | Description                                                                                                            | Value |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ----- |
| `global.imageRegistry`     | Registry of the bundled MongoDB's image, for example a mirror                                                          | `""`  |
| `global.imagePullSecrets`  | Registry secret names of the bundled MongoDB's image, as an array                                                      | `[]`  |
| `global.storageClass`      | StorageClass of the bundled MongoDB's volume                                                                           | `""`  |
| `global.namespaceOverride` | Override the namespace for resource deployed by the chart, but can itself be overridden by the local namespaceOverride | `""`  |

### **Common parameters**

| Name                    | Description                                                                                | Value  |
| ----------------------- | ------------------------------------------------------------------------------------------ | ------ |
| `nameOverride`          | String to partially override opc-router.fullname template (will maintain the release name) | `""`   |
| `fullnameOverride`      | String to fully override opc-router.fullname template                                      | `""`   |
| `I_do_accept_the_EULA`  | If this is false the OPC Router container won't be able to run.                            | `false` |
| `containerHistoryLimit` | The size of the history of deployments kept for potential rollbacks.                       | `10`   |

### **OPC Router parameters**

| Name                              | Description                                                                                                         | Default value       |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `image.repository`                | OPC Router image: `opcrouter/service` (with `mongodb.deploy=true`) or `opcrouter/runtime` (embedded database). May carry a registry. | `opcrouter/service` |
| `image.tag`                       | OPC Router image tag; empty means the chart's app version. See [Image versions](#image-versions).                   | `""` (`5.3`)        |
| `image.pullPolicy`                | OPC Router image pull policy.                                                                                       | `IfNotPresent`      |
| `imagePullSecrets`                | Registry secrets of the router pod.                                                                                 | `[]`                |
| `podAnnotations`                  | Annotations of the router pod.                                                                                      | `{}`                |
| `podSecurityContext`              | Security context of the router pod.                                                                                 | `{}`                |
| `securityContext`                 | Security context of the router container and the log rotation, see [Security](#security).                          | `{}`                |
| `resources`                       | Resource requests and limits of the router container.                                                               | `{}`                |
| `helperResources`                 | Resource requests and limits of the helper containers (project clone and auto-update, log folder, log rotation).    | `{}`                |
| `nodeSelector`                    | Node selector of the router pod.                                                                                    | `{}`                |
| `tolerations`                     | Tolerations of the router pod.                                                                                      | `[]`                |
| `affinity`                        | Affinity of the router pod.                                                                                         | `{}`                |
| `updateStrategy`                  | How the router pod is replaced; empty: `Recreate` with the embedded database, else RollingUpdate. See [Updates and downtime](#updates-and-downtime). | `{}` |
| `envVars`                         | Environment variables of the router container as `Name: "Value"` entries.                                         | `[]`                |
| `extraEnv`                        | Further environment variables as Kubernetes EnvVar entries, `valueFrom` included.                                  | `[]`                |
| `extraVolumes`                    | Further volumes of the router pod.                                                                                  | `[]`                |
| `extraVolumeMounts`               | Further volume mounts of the router container.                                                                      | `[]`                |
| `extraInitContainers`             | Further init containers, run after the chart's own.                                                                 | `[]`                |
| `probes.enabled`                  | Health probes of the router container, see [Health probes](#health-probes).                                        | `false`             |
| `probes.startupProbe.*`           | `periodSeconds`, `timeoutSeconds`, `failureThreshold` of the startup probe.                                         | `10`, `5`, `60`     |
| `probes.readinessProbe.*`         | The same for the readiness probe.                                                                                   | `10`, `5`, `3`      |
| `probes.livenessProbe.*`          | The same for the liveness probe.                                                                                    | `30`, `10`, `6`     |
| `prepareLogFolder`                | With the embedded database, create its log folder before the router starts.                                        | `true`              |
| `mongodbLogRotation.enabled`      | Rotate the embedded database's log by size, see [Storage](#storage).                                               | `false`             |
| `mongodbLogRotation.maxSizeMB`    | Size at which the log is rotated.                                                                                   | `200`               |
| `mongodbLogRotation.keepFiles`    | Number of rotated log files kept.                                                                                   | `4`                 |
| `mongodbLogRotation.checkIntervalSeconds` | How often the log size is checked.                                                                          | `600`               |
| `serviceAccount.create`           | Specifies whether a service account should be created.                                                              | `true`              |
| `serviceAccount.annotations`      | Annotations to add to the service account.                                                                          | `{}`                |
| `serviceAccount.name`             | Name of the service account to use. If not set and create is true, it is generated using the fullname.              | `""`                |
| `tests.image.repository`          | Image of the `helm test` pod.                                                                                       | `busybox`           |
| `tests.image.tag`                 | Tag of that image.                                                                                                  | `1.37`              |
| `tests.image.pullPolicy`          | Pull policy of that image.                                                                                          | `IfNotPresent`      |
| `tests.resources`                 | Resource requests and limits of the `helm test` pod.                                                                | `{}`                |

### **Web management parameters**

| Name                                      | Description                                                                                             | Default value |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------- |
| `webManagement.auth.disable`              | If false, the web management will require authentication to be accessed.                               | `true`        |
| `webManagement.auth.initialUser.name`     | The username of the initial user. If left empty, there will be no initial user.                         | `""`          |
| `webManagement.auth.initialUser.password` | The password of the initial user. If left empty, there will be no initial user.                         | `""`          |
| `webManagement.https.disable`             | If false, the web management will use https. This requires a TLS key and certificate to be set.         | `true`        |
| `webManagement.https.cert`                | The tls certificate used for https. Is overwritten by existingTlsSecret.                                | `""`          |
| `webManagement.https.key`                 | The tls key corresponding to the certificate used for https. Is overwritten by existingTlsSecret.       | `""`          |
| `webManagement.https.existingTlsSecret`   | An existing kubernetes.io/tls secret. Will overwrite cert and key.                                      | `""`          |

### **Service and Ingress parameters**

| Name                               | Description                                                                                           | Default value |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------- |
| `service.enabled`                  | If false, the application won't be reachable from outside the cluster.                                | `true`        |
| `service.type`                     | Type of the service. Possible values: ClusterIP, NodePort, LoadBalancer.                              | `ClusterIP`   |
| `service.port`                     | Port of the web management on the service.                                                            | `8443`        |
| `service.nodePort`                 | External port. When NodePort, this port will allow external access to the service.                    | `""`          |
| `service.externalIPs`              | External IPs. Reachable under these IPs, when traffic ingresses into cluster with IPs as destination. | `[]`          |
| `service.loadBalancerIP`           | LoadBalancer IP. Used by some cloud providers to add external load balancers.                         | `""`          |
| `service.annotations`              | Annotations of the service, for example for an internal load balancer.                                | `{}`          |
| `service.extraPorts`               | Further ports on the router container and the service, see [Extra ports](#extra-ports-environment-variables-volumes-and-init-containers). | `[]` |
| `service.publishNotReadyAddresses` | With probes on, route also to a router that is not ready; empty: only when the pod is replaced with `Recreate`. | `""`          |
| `ingress.enabled`                  | Create an Ingress for the web management.                                                             | `false`       |
| `ingress.className`                | Ingress class.                                                                                        | `""`          |
| `ingress.annotations`              | Annotations of the Ingress.                                                                           | `{}`          |
| `ingress.hosts`                    | Hosts and paths of the Ingress.                                                                       | `chart-example.local`, `/` |
| `ingress.tls`                      | TLS settings of the Ingress.                                                                          | `[]`          |

### **Volume parameters**

The same keys exist under `claims.inray` (`/data`) and `claims.log` (`/var/log/opcrouter`).

| Name                                         | Description                                                                                  | Default value |
| -------------------------------------------- | -------------------------------------------------------------------------------------------- | ------------- |
| `claims.*.capacity`                          | Requested size. Empty: an existing claim keeps its size, a new one gets the default in [Storage](#storage). | `""` |
| `claims.*.storageClassName`                  | StorageClass of the claim; empty uses the cluster's default.                                 | `""`          |
| `claims.*.keepAfterUninstall`                | Keep the claim when the release is uninstalled.                                              | `false`       |
| `claims.*.storageVolume.createVolume`        | Create a PersistentVolume for the claim with the settings below.                             | `false`       |
| `claims.*.storageVolume.reclaimPolicy`       | Reclaim policy of that volume.                                                               | `Retain`      |
| `claims.*.storageVolume.volumeType`          | Volume type of that volume.                                                                  | `local`       |
| `claims.*.storageVolume.volumeTypeOptions`   | Settings of the volume type.                                                                 | path          |
| `claims.*.storageVolume.mountOptions`        | Mount options of that volume.                                                                | `[]`          |
| `claims.*.storageVolume.nodeAffinity`        | Node affinity of that volume.                                                                | `{}`          |

### **Bundled MongoDB parameters**

| Name                          | Description                                                                                     | Default value           |
| ----------------------------- | ----------------------------------------------------------------------------------------------- | ----------------------- |
| `mongodb.deploy`              | If false, no MongoDB is deployed. Set it to false with the `opcrouter/runtime` image.          | `true`                  |
| `mongodb.replicaCount`        | Number of MongoDB pods. Must be 1: the router supports only a single-member replica set.       | `1`                     |
| `mongodb.image.registry`      | Registry of the MongoDB image.                                                                  | `docker.io`             |
| `mongodb.image.repository`    | Repository of the MongoDB image.                                                                | `bitnamilegacy/mongodb` |
| `mongodb.image.tag`           | Tag of the MongoDB image.                                                                       | `4.4.15`                |
| `mongodb.resources`           | Resource requests and limits of the MongoDB container.                                          | `{}`                    |
| `mongodb.auth.enabled`        | If false, the mongodb won't require any authentication to access.                               | `false`                 |
| `mongodb.auth.existingSecret` | Existing secret with mongodb credentials (keys: mongodb-root-password, mongodb-replica-set-key). | `""`                    |
| `mongodb.auth.rootPassword`   | Root password for the mongodb. Will override autogenerated or existing one in secret.           | `""`                    |
| `mongodb.auth.replicaSetKey`  | Replica set key for the mongodb. Will override autogenerated or existing one in secret.         | `""`                    |

Every other setting of the bundled Bitnami MongoDB chart, version 10.31.5 (in this repository under
`charts/opc-router/charts/`), can be given under `mongodb:` as well. Its optional containers use
Bitnami images whose versioned tags no longer exist either: for the metrics exporter set
`mongodb.metrics.image.repository=bitnamilegacy/mongodb-exporter` and `mongodb.metrics.image.tag=0.11.2`;
the image of the volume permissions container, `bitnami/bitnami-shell`, has no replacement there.

### **Project parameters**

| Name                                       | Description                                                                                          | Default value             |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------- | ------------------------- |
| `project.projectRepo`                      | URL to the git repository of an OPC Router project. Optional. Empty means no project gets loaded.    | `""`                      |
| `project.projectPath`                      | Path to the project .rpe file in the repository. Don't begin with '/'. Optional.                     | `""`                      |
| `project.configPath`                       | Path to a projects configuration file. Optional. Empty means no configuration file gets loaded.      | `""`                      |
| `project.importMode`                       | `clear` or `overwrite`, see [Loading a project](#loading-a-project-from-a-git-repository).           | `clear`                   |
| `project.gitImage.*`                       | `repository`, `tag`, `pullPolicy` of the image that clones the project.                              | `alpine/git`, `v2.47.2`   |
| `project.autoUpdate.disable`               | If false, the project is updated when it changes in the repository. Experimental.                    | `true`                    |
| `project.autoUpdate.interval`              | Interval in seconds the repository is fetched.                                                       | `300`                     |
| `project.autoUpdate.kubectlImage.*`        | `repository`, `tag`, `pullPolicy` of the kubectl image; its entrypoint must be `kubectl`.             | `registry.k8s.io/kubectl`, `v1.33.0` |
| `project.auth.ssh_secret`                  | An existing secret containing the ssh key under the key `ssh-privatekey`. Optional.                  | `""`                      |
| `project.auth.ssh_key`                     | SSH private key for accessing the git repository. Overwritten by ssh_secret, Optional.               | `""`                      |

## **Requirements of the OPC Router on Kubernetes**

Without these the router does not run, or does not run reliably:
- **Root start, capabilities, writable root filesystem.** The image starts as root and switches to its
  own service users. It needs user ID 0, the capabilities `CHOWN`, `SETUID`, `SETGID`, `FOWNER` and
  `DAC_OVERRIDE`, and a writable root filesystem. On OpenShift the default security context constraint
  does not allow this; the pod needs `anyuid` or an equivalent (not tested on OpenShift).
- **A persistent volume for `/data`.** It holds the configuration, the license identity and, with the
  `opcrouter/runtime` image, the database. A new or empty volume is a new system for licensing. Never
  copy the volume into a second running instance: both would carry the same license identity.
- **`/var/log/opcrouter` persistent.** An empty volume there stops every start once a database exists
  (the chart's init container covers this for the embedded database's log folder).
- **One router pod per data volume.** The router does not scale horizontally, see
  [High availability](#high-availability).
- **Outbound access to the license server.** Without a TPM, the license is synchronised online with
  `https://license.opc-router.com`, at startup and at least every 72 hours. TPM-based licensing does
  not fit Kubernetes: the identity also depends on the host name and the node's hardware.
- **An external MongoDB is a single-member replica set.** Name the one host and the set in the
  connection string (`mongodb://<host>:27017/?replicaSet=<name>`). Several hosts stop the router from
  starting, and losing a member of a larger set stalls it.
- **The web port with WebSockets.** 8080, or 8443 with HTTPS, is the only port that always has to be
  reachable; an Ingress or a proxy must pass WebSockets through.
- **Memory for the `opcrouter/runtime` image:** a limit of at least 3 to 4 GiB. Its database sizes its
  cache from the limit and leaves 2 GB to the router.

## **Storage**

| Claim | Mounted at | Holds | Size of a new installation |
| ----- | ---------- | ----- | -------------------------- |
| `inray-<release>-opc-router` (`claims.inray`) | `/data` | configuration, license identity; with the embedded database also the database | `1Gi` with the bundled MongoDB, `10Gi` with the embedded database |
| `log-<release>-opc-router` (`claims.log`) | `/var/log/opcrouter` | the router's logs (runtime and web management, up to 2 x 1 GB each); with the embedded database also its log | `4Gi` with the bundled MongoDB, `6Gi` with the embedded database |

An existing claim keeps its size: a bound claim cannot shrink, and growing it needs a StorageClass
that allows volume expansion. To grow one, set `claims.*.capacity` to the new size. To see what the
router uses:
```shell
kubectl exec deploy/my-opcrouter-opc-router -c opc-router -- du -sch /data/* /var/log/opcrouter/*
```
The embedded database writes its own log, `/var/log/opcrouter/mongodb/mongod.log`, and the image
does not rotate it: on a long-running installation it fills the log volume, and the database stops.
`mongodbLogRotation.enabled=true` rotates it by size and keeps a few rotated files, at most about
`(keepFiles + 1) x maxSizeMB`.

The embedded database is a MongoDB and needs a file system MongoDB supports for its data files; put
`/data` on a block-storage volume rather than a network file share (see MongoDB's production notes).

## **Updates and downtime**

When the router is upgraded or its settings change, Kubernetes replaces its pod:
- **With the embedded database** the chart uses `Recreate`: the old pod stops before the new one
  starts, because two pods on one database cannot both start.
- **With the bundled MongoDB** Kubernetes' default `RollingUpdate` applies: the new pod starts while
  the old one still runs, so for a while two routers run the same project. Enable the
  [health probes](#health-probes) there: the old router then keeps serving until the new one is
  ready. In our measurement on one node no request to the service failed during such an update, and
  both routers were ready at the same time for 7 to 11 seconds; without probes, requests failed for
  about 6 seconds.
- **On clusters with several nodes** a rolling update stalls in every mode: the new pod lands on
  another node, where it cannot attach the `ReadWriteOnce` volume the old pod still holds. Set
  `Recreate` there:
```yaml
updateStrategy:
  type: Recreate
  rollingUpdate: null
```
With `Recreate` the router is unavailable from the stop of the old pod until the new one is ready; on
our test systems the router answered 9 to 36 seconds after its start, the longest with the database
migration of a new version, and longer when its image first has to be pulled. Keep that short by
keeping the image on the nodes (pull policy `IfNotPresent`, an exact image tag, the image pulled ahead
of a planned upgrade), and see when the router is back with the [health probes](#health-probes). Uninterrupted operation needs the router's redundancy mode, see
[High availability](#high-availability).

## **Health probes**

`probes.enabled=true` adds a startup, a readiness and a liveness probe to the router container:
startup and liveness ask `/health/runtime/live`, readiness `/health/runtime/ready`, on the web port and
without login. A runtime that runs but is not ready, for example without a valid license, is not
restarted. Whether the service still routes to such a pod follows from how the pod is replaced
(`service.publishNotReadyAddresses`, empty by default): with `Recreate` it does, so the web management
stays reachable to fix it; with a rolling update it does not, so that clients reach only the ready
router while its successor starts. A pod that is not ready stays reachable directly with
`kubectl port-forward pod/<pod name> 8080`. With HTTPS the probes use the HTTPS web port, because port
8080 only redirects.

The probes stay off by default because only these OPC Router builds have the routes: 5.3.6001 and later
5.3 builds, 5.4.5005 and later, and every build from 5.5 on. Older builds answer every address with the
web management's start page, so a probe there always succeeds and detects nothing. The image tag `5.3`
is such a newer build, but a node that pulled an older `5.3` build keeps running it under the pull
policy `IfNotPresent`, see [Image versions](#image-versions).

The startup probe allows 10 minutes (`periodSeconds` x `failureThreshold`), enough for the database
migration on the first start of a new version.

## **Security**

- **The web management has no login by default** (`webManagement.auth.disable=true`). Whoever can
  reach the service can change the router's configuration. Set `webManagement.auth.disable=false` and
  an initial user; to keep its password out of the values, leave
  `webManagement.auth.initialUser.password` empty and read it from a Secret:
```yaml
extraEnv:
  - name: INITIAL_PASSWORD
    valueFrom:
      secretKeyRef:
        name: opc-router-initial-user
        key: password
```
- **The bundled MongoDB has no login by default** (`mongodb.auth.enabled=false`); see the warning
  below before you enable it.
- **The service account** gets permissions and an API token only with the project auto-update: a Role
  that may list and delete the pods of the namespace, so a new project version restarts the router.
- **The security context** that grants only what the router needs:
```yaml
securityContext:
  capabilities:
    drop:
      - ALL
    add:
      - CHOWN
      - SETUID
      - SETGID
      - FOWNER
      - DAC_OVERRIDE
```
Running as another user, dropping these capabilities or `readOnlyRootFilesystem: true` stop the router.

## **WARNING: MongoDB root password and replica key set**

When using the mongodb container, keep in mind that that the root password and replica key set can only be set once, as upon initial declaration they are stored in a persistent volume. This may be an issue when using automatically deploying the chart using ArgoCD or Flux, as automatic redeployments can cause the root password to be regenerated when not having set static values for them in the values.yaml. This however will only make the database inaccessible to the OPC Router, as it will use the new passwords, though the mongodb still uses the old initial passwords. Thus it is highly recommended to set `mongodb.auth.existingSecret` or `mongodb.auth.rootPassword` and `mongodb.auth.replicaSetKey` when not manually deploying the chart for testing purposes.

## **Image versions**

The default image tag, `5.3`, moves with every maintenance build of OPC Router 5.3, and so does a tag
like `5.7`. Under the pull policy `IfNotPresent` a node keeps the build it pulled first, so after a
reschedule two nodes can run different builds of the same tag. In production pin an exact version,
for example:
```shell
--set image.tag=5.7.5000.16
```
Like the movable tags, the exact tags on Docker Hub are multi-architecture images.

## **Using the `opcrouter/runtime` image**

By default the chart runs the `opcrouter/service` image, which has no database of its own, and deploys
a MongoDB next to it. The `opcrouter/runtime` image carries its own database:
```shell
helm install my-opcrouter opc-router/opc-router \
  --set image.repository=opcrouter/runtime \
  --set mongodb.deploy=false \
  --set I_do_accept_the_EULA=true
```
Always set `mongodb.deploy=false` with it: otherwise the chart deploys the separate MongoDB as well,
and the router uses that one.

The embedded database lives on the data volume, which a new installation therefore creates with 10Gi,
see [Storage](#storage). Give the router container a memory limit of at least 3 to 4 GiB.

## **Managed clusters with admission policies**

Managed clusters often reject pods without resource limits, forbid broad permissions for service
accounts and reach their images through a registry of their own. Every container of the chart takes
resources, and every image can be redirected:
```yaml
image:
  repository: myregistry.example.com/opcrouter/runtime
  tag: "5.7.5000.16"
mongodb:
  deploy: false
serviceAccount:
  create: false
resources:
  requests:
    cpu: 500m
    memory: 4Gi
  limits:
    cpu: "2"
    memory: 4Gi
helperResources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 256Mi
tests:
  image:
    repository: myregistry.example.com/library/busybox
  resources:
    limits:
      cpu: 100m
      memory: 64Mi
service:
  type: LoadBalancer
  annotations:
    # an internal load balancer on Azure; other providers use their own annotation
    service.beta.kubernetes.io/azure-load-balancer-internal: "true"
  extraPorts:
    - name: opcua
      port: 49420
nodeSelector:
  agentpool: user
updateStrategy:
  type: Recreate
  rollingUpdate: null
claims:
  inray:
    capacity: 10Gi
  log:
    capacity: 6Gi
```
With the bundled MongoDB, give it resources under `mongodb.resources` and redirect its image with
`global.imageRegistry`. With a project from git, `project.gitImage` and
`project.autoUpdate.kubectlImage` name the helper images. `service.loadBalancerIP` is deprecated in
Kubernetes; providers offer an annotation for a fixed address instead.

## **Using Ingress or reverse proxies**

The rerouting of the traffic for to the OPC Router web management may require some extra configuration. Generally, when some form of reverse proxy is being used, the `ASPNETCORE_FORWARDEDHEADERS_ENABLED` environment variable needs to be set to `true`. When `ingress.enabled` is set to `true` this is already automatically done.

In some configurations it is desirable to change the base path for the OPC Router web management. This always requires setting the `WEB_BASE_PATH` environment variable to the new base path for the OPC Router web management to properly function.

For configuring environment variables, refer to [Adding extra environment variables](#adding-extra-environment-variables).

## **Extra ports, environment variables, volumes and init containers**

`service.extraPorts` opens a port on the router container and on the service, for example the OPC UA
server of a project or a plug-in's listener:
```yaml
service:
  extraPorts:
    - name: opcua        # at most 15 lowercase letters, digits and '-'
      port: 49420
      # targetPort: 49420  container port, defaults to port
      # protocol: TCP
      # nodePort: 31420    NodePort and LoadBalancer only
```
The OPC UA server plug-in advertises the pod's host name in its `opc.tcp` endpoints. Clients that keep
the address they dialled work through the service; clients that switch to the advertised address
need that name to resolve.

`extraEnv` takes Kubernetes EnvVar entries, so a value can come from a Secret or a ConfigMap (see
[Security](#security)). `extraVolumes` and `extraVolumeMounts` add volumes to the router container,
for example an `odbc.ini` for the ODBC plug-in:
```yaml
extraVolumes:
  - name: odbc
    configMap:
      name: odbc-ini
extraVolumeMounts:
  - name: odbc
    mountPath: /etc/odbc.ini
    subPath: odbc.ini
```
`extraInitContainers` run after the chart's own init containers.

## **High availability**

The router does not scale horizontally: one pod per data volume, and `replicas` stays 1. Several
MongoDB members are not supported either; `mongodb.replicaCount` must stay 1. High availability is the
router's redundancy mode, two independent instances with a primary and a secondary, which this chart
does not deploy yet.

## **Loading a project from a git repository**
Please refer to [this sample project](https://github.com/OPC-Router/helm-sample-project) on general information of how to deploy a OPC Router project from a git repository onto a kubernetes cluster using this helm chart.

At every start the router imports the project. `project.importMode` decides how:
- `clear` (default) deletes the configuration first, so the router runs exactly the project. OPC Router
  5.5, 5.6, 5.7 and 5.4 builds after 5.4.6009 stop at this step and the web management never starts
  (a known defect); use `overwrite` with them.
- `overwrite` imports the project over the existing configuration: what the project contains replaces
  what is there, everything else stays. It needs OPC Router 5.1.5001 or later.

With `project.autoUpdate.disable=false` a container fetches the repository every
`project.autoUpdate.interval` seconds and restarts the router when the project has changed. At its
start it installs `curl` from the Alpine package repository, so it needs access to it.

## **Adding extra environment variables**

To add extra environment variables (useful for inserting into the config.yaml of your project), use the `envVars` property.
```yaml
envVars:
  - <VarName>: "<VarValue>"
```
A helm install command can also be issued with specifiying multiple environment variables:
```shell
$ helm install my-opcrouter opc-router/opc-router \
  --set envVars[0].TESTVAR="successful" \
  --set envVars[1].OtherVariable="42" \
  --set envVars[2].yetAnotherVar="false" \
  --set I_do_accept_the_EULA=true
```
Values from a Secret or a ConfigMap go into `extraEnv`, see
[Extra ports, environment variables, volumes and init containers](#extra-ports-environment-variables-volumes-and-init-containers).
