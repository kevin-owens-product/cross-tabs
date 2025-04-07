# TROUBLESHOOTING

A curated list of issues encountered when working with the repository. Feel free to add your questions & solutions.

## HTTP server is already running on the desired port

-   Check if there is not running http-server instance and kill it.

```
sudo lsof -n -i :80 | grep LISTEN
# Once you get the PID of the process using the port use this to kill it:
kill PID
```

## `bus error` when running `elm make`

-   This can be related to ARM binaries downloaded for Elm. Ensure to check your version is compatible with your architecture ([elm](https://www.npmjs.com/package/elm) / [@lydell/elm](https://www.npmjs.com/package/@lydell/elm))
