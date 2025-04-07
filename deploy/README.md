# Deployment of Platform

## TODO: Modify this in the close future

Deployment pipeline for platform with support for atomic revision switching
and feature branch releases.

## Pipeline

The deployment flow consists of 4 independent steps:

-   generate revision for new version (based on git hash and timestamp)
-   replace relative paths to assets with absolute URLs pointing to CDN **provided by separate package**
-   upload assets recursively to Google Cloud Storage **provided by separate package**
-   load index.html to Redis and mark this new revision as active

#### Requirements:

-   [platform-tools](https://github.com/GlobalWebIndex/platform-tools)
-   It requires Redis running locally and access to the `pro-next-assets-<environment>` bucket on GCP.
-   You (or your service account) must have GCP _write_ permissions for the target bucket:
    -   A) to use your credentials: `gcloud auth application-default login`.
        -   to pass your credentials to docker you can use: `-v ~/.config:/root/.config`
    -   B) to use some service account: `export GOOGLE_APPLICATION_CREDENTIALS="/home/martin/.ssh/gwi-core-calculations-s.json"`.

## Deploy

Install [platform-tools]() from github via yarn:

```
yarn global add 'git+ssh://git@github.com/GlobalWebIndex/platform-tools.git'
```

There is a Makefile in this directory which will run the whole cycle:

```
$ pwd
pro-next/deploy/

# just release
$ TARGET_ENV=testing TARGET_REDIS=local make release

# release and activation
$ TARGET_ENV=testing TARGET_REDIS=local make release-and-activate
```

## Testing Revisions Proxy

You can use kubectl port-forward to proxy to testing redis to read and change revisions there.
For that you'll need correctly setup kubectl and gcp tools on your system.

```
kubectl port-forward service/pro-next-redis-ha-haproxy 6379:6379 -n platform
```

-   testing: `--context=gke_core-calculations-t_europe-west1-b_core-t`
-   staging: `--context=gke_core-calculations-s_europe-west1-b_core-s`
-   production: `--context=gke_core-calculations-p_europe-west1_core-p`

## Components

-   [replace-paths](https://github.com/GlobalWebIndex/platform-tools/tree/master/replace-paths) - CLI utility written in Node for recursively replacing paths within source code
-   [revision-gen.sh](revision-gen.sh) - a simple Bash script to generate build revisions
