# CoolTip

The tooltip with only SCSS

![Cooltip](Cooltip.png)

See demo by running `make` in this directory and then opening the `index.html`
file.

Cooltips have three main functions:

-   `with` - place CoolTip with desired orientation
-   `withOffset X` - place CoolTip and move it by the defined `X` in the direction of orientation - see above
-   `withOffsetHtml` - allow you to have your own Html inside the CoolTip.

`Left` and `Right` are placed at the `50%` of the wrapped object by default, if you use `withOffset` on them, the offset is taken from the top of the wrapped object.
