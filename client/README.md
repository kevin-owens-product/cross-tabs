# Getting Started with pro-next

Second version of GWI user-facing platform (first was [pro](https://github.com/GlobalWebIndex/pro)) where the main new development happens. The goal of this repository is to prevent using outdated and unstable libraries for new features development. **Don't hesitate to ask the anyone in the team for help if you find yourself stuck in the setup process and bumping your solutions into the [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING) file.**

## Knowing the Platform

pro-next is actually served through a MFE architecture managed by [platform2-kernel](https://github.com/GlobalWebIndex/platform2-kernel). In this repo we also make use of the [platform2-web-components](https://github.com/GlobalWebIndex/platform2-web-components) like Attribute Browser. We also use a lot these two tools, which require the **[VPN setup](https://globalwebindex.atlassian.net/wiki/spaces/TECH/pages/1724710913/OpenVPN)**:

-   **[admin](https://admin.in.globalwebindex.com/)**. Used to set customer permissions and flags that grant or remove access to different features.
-   **[fe-configuration](https://fe-configuration.in.globalwebindex.com/)**. Used to set the commit hashes deployed to our different environments (testing, staging, production) and Feature Branches (e.g. https://app.globalweb.index.com/release-elm).

## Setup

### Required steps

You'll need to install some global dependencies first:

-   **[Node.js](https://nodejs.org)** (recommended installation through [nvm](https://github.com/nvm-sh/nvm))
-   **[Yarn](https://yarnpkg.com/)** (preferred over [npm](https://www.npmjs.com/))
-   **[Elm](https://elm-lang.org/)**

### Install dependencies

Now you need to install project dependencies. Use `nvm use` inside the root folder to use that Node.js version.

> If you haven't followed the recommendation of installing Node.js through nvm you still can try to install the dependencies and see if it works.

To install Node.js dependencies which are responsible for build tools of this project run this command in the root folder of the repo:

```
yarn
```

> If you haven't followed recommendation of installing yarn you can use npm instead and run `npm install`.

## Run Project Locally

Before running locally make sure you have this customer flags checked:

-   tv_rf_user
-   TVRF 2.0 visible in pro-next
-   xb_20_visible_in_pronext
-   Dashboards 2.0 visible in pro-next
-   Dashboards GWI creator OR Dashboards non-GWI creator (check one OR the other but not both)
-   persona_card
-   P1 User After Sunset
-   can_share_open_access_dashboard

If you don't have/can't see these flags, simply go to [admin](https://admin.in.globalwebindex.com/) behind the VPN (testing, staging or production) and follow these steps:

-> Search for your email address in UM
-> Users
-> Input your email in _Filter by email:_
-> Apply filters
-> Click on your user
-> Edit Customer Features
-> Check any flags you want
-> Click _Save_

Once you have everything setup you can run the dev-server with HMR from your machine using:

```
make start
```

And you're all set!

> First compilation takes about 14GB of RAM, which is just too much... If you find yourself in Out Of Memory issues, try adding extra swap memory to your machine. If it's still not working, get in touch with someone in the team and don't forget to show your solution in the [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) file.

[Makefile](../Makefile) commands also accept arguments. For example, if you want to run locally in _staging_ environment you can use the `TARGET_ENV` flag like this:

```
TARGET_ENV=staging make start
```

This starts HTTP server on port `3000` with staging environment. Open this URL inside your browser [localhost:3000](http://localhost:3000) and wait for compilation to finish.

### Environment options

-   **`NODE_ENV`**: use optimizations, minification, logging middleware? (`development` = yes)

    -   Possible values: `development | production`
    -   Default: `development`

-   **`TARGET_ENV`**: environment forwarded to the app (`Config.Main.Stage`), influencing API URLs used etc.
    -   Possible values: `development | testsuite | testing | staging | production`
    -   Default: `development`

All of these can be used like `BUILD_MODE=all make start` or `TARGET_ENV=production NODE_ENV=development make build`. You **don't** need to set `Config.Main.development.uri` in any way if you use `TARGET_ENV`.

### Running tests

Yarn or npm should install all test dependencies to local `node_modules` of this project. To run the tests simply use:

```
make test
```

For local TDD you can run single test in watch mode with provision additional `TEST_OPTIONS` variable. But this can be used only for running part of the test, not for running all with `make test` command:

```
make test_share TEST_OPTIONS=--watch
```

Finally, if you wanna ensure you don't miss anything run the complete test suite like:

```
make review && make review-styles && make test
```

This will ensure everything is alright before you push anything to upstream.

### Building project

This project can be built manually.

```
make build
```

This will build the application without running the server. You can also use `BUILD_MODE` env variable here.

## Working on Something

Grab a ticket from the ATCom 2020+ board and start working on your local machine:

```
# For example for the 'Task' ticket ATC-3248 and being on ˜/Repos/pro-next (master)
git pull
git checkout -b feature/ATC-3248
# And you'll be set to work on feature ticket
```

### Style Guide

See [STYLE.md](../docs/STYLE.md).

## Pushing Changes & Deploying

**All changes in this repository should come through a Pull Request**. [A custom build image](https://github.com/GlobalWebIndex/infra/tree/master/apps/curl-jq) is used to run tests configured in [gwi-platform-ta repository pipeline](https://github.com/GlobalWebIndex/gwi-platform-ta#pipeline) via `drone promote` using **drone api**. Every push to master in this repository will trigger all the tests configured in [gwi-platform-ta](https://github.com/GlobalWebIndex/gwi-platform-ta#pipeline).

Some things to bear in mind:

-   Deployment is fully automated. It's not recommended to attempt to run deploy from your machine.
-   Production server info is located in [server](../server/README.md).
-   Production build and deploy happens as part of build pipeline in [drone](https://drone.in.globalwebindex.com/GlobalWebIndex/pro-next).
-   VPN is required for accessing the drone server.

We use four prefixes for our PRs. These are:

-   _feature_. Most used. For new features added into the application.
-   _chore_. For general improvements, cleanups, refactorings...
-   _spike_. Experiments, not meant for production, prototypes...
-   _fix_. Bugfixes, solutions to common issues.

However, not all branches are being deployed. `fix/` prefix is special as it creates feature branches in all of `testing`, `staging` and `production` environments. For example:

| git branch         | testing                                           | staging                                                   | production                         |
| ------------------ | ------------------------------------------------- | --------------------------------------------------------- | ---------------------------------- |
| feature/new_server | https://app-testing.globalwebindex.com/new_server | https://app-staging.globalwebindex.com/feature/new_server | --                                 |
| chore/cleanup      | https://app-testing.globalwebindex.com/cleanup    | https://app-staging.globalwebindex.com/cleanup            | --                                 |
| spike/experiment   | https://app-testing.globalwebindex.com/experiment | https://app-staging.globalwebindex.com/experiment         | --                                 |
| fix/bug            | https://app-testing.globalwebindex.com/bug        | https://app-staging.globalwebindex.com/bug                | https://app.globalwebindex.com/bug |

_For information about new prototype of deployment see [deploy](../deploy/README.md)._

## Writing Tests

-   Elm's type system allows us to not test as often as we would have to in e.g. JavaScript. So the first principle here is "write stuff in such a way that you **don't have to test it.**" You might have heard the phrase ["Make impossible states impossible."](https://www.youtube.com/watch?v=IcgmSRJHu_8) - do that!

-   We do [**unit tests**](https://package.elm-lang.org/packages/elm-explorations/test/latest/Test#test) of crucial business logic that isn't enforced by the type system.

-   We do [**fuzz tests**](https://package.elm-lang.org/packages/elm-explorations/test/latest/Test#fuzz) (i.e. property-based testing; think of them as of parameterized and randomized unit tests). If you write an unit test, there's a good chance it can be made better (catch edge cases) by randomizing the data.

-   We try to do **regression tests** for found bugs (i.e. "make sure this bug doesn't bite us ever again"). Sometimes it's not worth it, but we consider it in each specific case.

-   We generally DON'T do [**view tests**](https://package.elm-lang.org/packages/elm-explorations/test/latest/Test-Html-Query#contains), but sometimes those are the right choice for regression tests.

-   We DON'T do **end-to-end tests** - in theory they're great for testing the whole system but in practice are not worth it and are pain to maintain.

-   If there's a need to guarantee an invariant of a module's `Model`, we use [**update fuzz-tests**](https://package.elm-lang.org/packages/Janiczek/architecture-test/latest/), especially [`invariantTest`](https://package.elm-lang.org/packages/Janiczek/architecture-test/latest/ArchitectureTest#invariantTest). For more about update fuzz-tests, see [this talk](https://www.youtube.com/watch?v=baRcusTHc8E).

-   If there's a need to guarantee an aspect of how a module's `Msg` works, we use [**update fuzz-tests**](https://package.elm-lang.org/packages/Janiczek/architecture-test/latest/) too, but in this case the [`msgTest`](https://package.elm-lang.org/packages/Janiczek/architecture-test/latest/ArchitectureTest#msgTest) and [`msgTestWithPrecondition`](https://package.elm-lang.org/packages/Janiczek/architecture-test/latest/ArchitectureTest#msgTestWithPrecondition).

## Local Development in P2

> NOTE: platform2-kernel reload is not triggered when a change is made in an Expert Tools app, so it needs to be rebuilt manually. This is something that'd be nice to have.

Usually, when you run `make start` you'll find yourself in P1 with an old interface. Actually this doesn't matter, because applications are actually deployed as a MFE architecture. However, if you still wanna use P2 locally, follow these steps:

-   Run `make start_crosstabs_for_P2` in the root of pro-next. This would be different for different apps, for example `make start_tvrf_for_P2` for TVRF.
-   Clone the P2 kernel, which is located at https://github.com/globalwebindex/platform2-kernel
-   Make a GitHub token with package access and follow these instructions to set it up: https://github.com/globalwebindex/platform2-kernel#npmrc
-   Run `yarn && yarn start --env LOCAL_APP_URL=http://localhost:3900/crosstabs.js LOCAL_APP_NAME=crosstabs` in the root of the P2 kernel repository. Again, you need to vary the name of the app in this command, so replace `crosstabs/crosstabs.js` with `crosstabs/crosstabs.js` to run Crosstabs for example.

Now you have the P2 app running usually on http://localhost:4200, where all applications are from the testing environment but yours, which is also in watch mode.

If you want to have all apps running locally in P2 follow these steps:

-   Go to [app/types/constants.ts](https://github.com/GlobalWebIndex/platform2-kernel/blob/develop/app/types/constants.ts#L19) inside your local platform2-kernel clone and paste these values in `LOCAL_MFE_URLS_OVERRIDE`:

```typescript
/* 
    The below constant is used for local testing purposes and overrides the configurations 
    from the response of getConfiguration API. 
    The override URLs are working only when the application runs in development mode.
*/
export const LOCAL_MFE_URLS_OVERRIDE = new Map<string, string>([
    [MicrofrontendName.CROSSTABS, "http://localhost:3900/crosstabs.js"],
    [MicrofrontendName.TV_RF, "http://localhost:3900/tv-study.js"]
]);
```

-   Run `make start_for_P2`.
-   Inside your local platform2-kernel clone run `yarn start`.
-   Now you have every app running locally in local P2 kernel. Tradeoff is you are not in watch mode.
