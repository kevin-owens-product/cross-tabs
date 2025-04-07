# DEBUGGING

Debugging in functional languages is harder than in conventional ones. But that doesn't
mean it's not possible. Luckily, since Elm is a language that transpiles to JS, we have
room to use the powerful tools browsers like Google Chrome offer. Here's a curated list
of tips to make it easier your Elm debugging.

## `Debug.log`

As simple as it sounds, most of the time you won't need much more than this. Good places
to put some `Debug.log`s are the `update` functions inside any application module. For
example, put a `Debug.log` like this in [Detail.elm](./client/crosstab-builder/XB2/src/XB2/Page/Detail.elm): 

```elm
update :
    Config msg
    -> Flags
    -> XBStore.Store
    -> XB2.Share.Store.Platform2.Store
    -> Msg
    -> Model
    -> ( Model, Cmd msg )
update config flags xbStore p2Store msg model =
    let
        update_ : ( Model, Cmd msg )
        update_ =
            case Debug.log "Detail.msg" msg of
                NoOp ->
                    ( model, Cmd.none )

                FetchManyP2 toFetch ->
                    model
                        |> Cmd.withTrigger (config.fetchManyP2 toFetch)
...
```

With this you will have nice logs showing all the data flowing through the application.
You can also use [Elm Debug Helper](https://chrome.google.com/webstore/detail/elm-debug-helper/edlhclhffmclbhgifomamlomnfolnepa)
to have more visual objects in the _Console_ output.

## Debugging JSON decoders

JSON decoders are one of the hardests things to debug in Elm... But this little snippet
should do the trick:

```elm
module Json.Debug exposing (json)

import Json.Decode as Decode exposing (Decoder)


json : String -> Decoder a -> Decoder a
json message decoder =
    Decode.value
        |> Decode.andThen (debugHelper message decoder)


debugHelper : String -> Decoder a -> Decode.Value -> Decoder a
debugHelper message decoder value =
    let
        _ =
            Debug.log message (Decode.decodeValue decoder value)
    in
    decoder
```

This `Json.Debug.json` function will show the decoding result, wether it fails or succeeds.
To use it, simply import it in any module you want and input your label:

```elm
module Foo exposing (..)

import Json.Debug as Debug
import Json.Decode as Decode exposing (Decoder)


type alias Bar =
    { fooBar : String }

...

decodeBar : Decoder Bar
decodeBar =
  Decode.map Bar Decode.string
      |> Debug.json "Result of `decodeBar`"

...
```

## Elm time-travel debugger

With Elm time-travel debugger you get to see every single `Msg` fired by the app
alongside the model state. Really great for better visual experience but it consumes a
lot of resources. Unless you have a really beefy computer, you'll see that this method is
way too slow for this project. We recommend to stick to `Debug.log`, but if you still
however want to use it you can modify `debug: boolean` field in _elm-webpack-loader_ to
achieve it.

```javascript
  devMode ? 'elm-hot-webpack-loader' : null,
  {
    loader: 'elm-webpack-loader',
    options: {
      debug: true,
      optimize: !devMode,
      pathToElm: 'node_modules/.bin/elm'
    }
  }
].filter(x => x) // non-nulls
```

## Performance tab in Chrome Dev Tools

Really useful to [see the parts in the scripts that take a long time to load](https://developer.chrome.com/docs/devtools/performance/).
However, Elm code can become really obfuscated, so it is recommended for you to take
these steps first.

In [webpack.config.js](./webpack.config.js) set `mode: string` and
`devtool: string` as:

```javascript
  pathinfo: false,
  publicPath: '/'
},
mode: 'production',
devtool: 'source-map',

resolve: {
  alias: {
```

This should allow you to travel quickly to the references inside the performance profile
functions.

## Patch Elm code

Sometimes all the above options are not enough to get what you want. But with the steps
above, surprisingly, Elm outputs a fairly easy to read JS, so you can take advantage of
this and add [console.time()](https://developer.mozilla.org/en-US/docs/Web/API/console/time),
[console.log()](https://developer.mozilla.org/es/docs/Web/API/console/log),
[arguments.callee.caller](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/arguments/callee),
etc... You can also modify kernel functions and better understand its behaviour.
But _webpack-dev-server_ serves bundles from memory, so you'll need to setup the assets
to be fetched from disk. To do it modify `writeToDisk: boolean` field inside
[devServer](https://webpack.js.org/configuration/dev-server/#devserver) object:

```javascript
  return plugins;
})(),
devServer: {
  writeToDisk: true,
  inline: true,
```

Now you'll have bundle files inside the [build](./build) folder, but you'll still be
getting bundle files from memory. To fetch the local JS, simply add this to the
[index.html](./client/app-monolithic/src/index.html):

```html
</head>
<body>
  <script src="/build/app.js"></script>
</body>
```

And you're all set! Remember to remove any `"use strict";` that conflicts with the
changes you want to make in _/build/app.js_.

## Debugging Attributes Browser (platform2-web-components)

You can make easier the debug of the Attributes Browser to know the state of each Event.

Just open your navigator Devtool, go to application and add a field to the cookies.

![Dev Tools](https://github.com/GlobalWebIndex/pro-next/assets/39096665/4fbaa05b-6dd5-4c41-a985-02df98d8ee7f)

Now you get new logs on the console from platform2-web-components

## Debugging with the kernel

In this process we will see how to debug multiple applications using KERNEL.  
In the next example we will debug 3 applications (kernel, pro next crosstab and wc)

Required:

> -   install all the applicationes (using git clone)
> -   pro-next: https://github.com/GlobalWebIndex/pro-next
> -   kernel: https://github.com/GlobalWebIndex/platform2-kernel
> -   wcs: https://github.com/GlobalWebIndex/platform2-web-components

Kernel:

> -   Use: yarn && yarn start --env LOCAL_APP_URL=http://localhost:3900/crosstabs.js LOCAL_APP_NAME=crosstabs

Wcs:

> -   Use: yarn build (before use yarn install)

Pro-next:

> -   Change this file in your local (the route must point to your local wc) :
>     -   <img width="890" alt="image" src="https://github.com/GlobalWebIndex/pro-next/assets/39096665/7bd28d3a-345c-4f6f-aee3-c0d7b7627ab6">
>     -   // @ts-ignore

        import { AttributeBrowserLeftWebComponent } from "../../platform2-web-components/lib/attributeBrowserLeft/index.js";

> -   :warning: You cant start all pro-next!
> -   In case you use crosstab, use: make start_crosstabs_for_P2

---

:warning: Tips to avoid errors:

> -   In platform2-kernel change 2 lines in app/types/constants.ts like this:
> -   ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/d3116d9c-86b8-47e5-ba3a-a07d90630bd5)
