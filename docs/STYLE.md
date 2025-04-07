# Style Guide

How we style our code.

## Pull Request Style

- As small as possible (<400 LOC)
- Describe what you're doing
- Use as many labels as possible
- Implement whole functionality
- No dead code ([elm-review](https://package.elm-lang.org/packages/jfmengels/elm-review/latest/) forces this)
- 1 review and approval needed to merge
- All checks should pass
- Make it easy to be reviewed (<1h if possible)
- Keep consistent formatting

## Code Style

We have a say:

> Humans are only geniuses for 20 minutes.

This holds true almost every day 😝. That's why **we look more over readability** than _obscure solutions with cool one liners and extreme low-level performance_. At general **it'd be best if your code is rapidly understood by one quick glance**. Here's a curated list of tips that can help you to achieve that:

### Explain Like I'm 5

Don't be afraid to add comments, **they greatly improve the speed to understand the code!** However, you don't need to comment before every single line you write, so choose wisely. Some good places to always have documentation are the high-usage top-level exposed funtions of any module:

```elm
module User exposing (..)


type alias User =
    { id : Int
    , name : String
    , comments : List String
    }


process : User -> User
process user =
    ...  -- Ummmhh... What are we exactly processing? ❌
```

```elm
module User exposing (..)


type alias User =
    { id : Int
    , name : String
    , comments : List String
    }

{-| Check for user.comments length and shrink
    the list in case it exceeds 250, dropping the
    items from the head.
-}
process : User -> User
process user =
    ...  -- Okay, so this is what removes the old comments
         -- after the page loads! ✅
```

### Keep It Super Simple

Work with small functions that are easy to understand. A big `case..of` is sometimes better and enough.

### Respect `90` column limit

Not a hard limit, but avoid getting past it too much. Usually, you should not need more than 6 indentations. Going above this limit is a signal that your code needs some refactoring, like moving some `let..in` functions to the top-level.

### Use `let..in` blocks for values

Avoid using `let..in` blocks as a way to store subfunctions. The more functions a `let..in` block has, the harder it becomes to debug. There's nothing wrong from using a helper function from time to time, but it's best to keep all of them as top functions easy to test.

### Fill every `case..of` branch if possible

Avoid using the wildcard pattern `_` as much as you can. For example:

```elm
type UserPlan
	= Professional
	| Guest

planToString : Plan -> String
planToString plan =
	case plan of
		Professional ->
			"Professional"
		_ ->
			"Guest"
```

could better be replaced with:

```elm
type UserPlan
	= Professional
	| Guest

planToString : Plan -> String
planToString plan =
	case plan of
		Professional ->
			"Professional"
		Guest ->
			"Guest"
```

This way if you ever add a new `UserPlan` type, the compiler will guide you through its error messages so you won't miss anything.

### Use qualified imports

Prefer

```elm
import List.NonEmpty as NonEmpty
...
someNonEmptyList
	|> NonEmpty.unique
```

than

```elm
import List.NonEmpty exposing (unique)
...
someNonEmptyList
	|> unique
```

for better readability. With this you can quickly see from where those functions are coming from and avoid confusion with other modules ("Is this `unique` from `List` or `List.NonEmpty`?"). There are some exceptions with types or high-usage functions.

### Use consistent import naming

`import Json.Decode as Decode` should be `import Json.Decode as Decode` in every module.

### Use `Maybe`, but Just in place

The `Maybe` type is what null should have been from the beginning, but you shouldn’t let it go too far. Passing a `Maybe` through several functions will make the code harder to read and maintain. So, once you have the chance to unwrap a `Maybe`, **do it!** Also prefer `Result` over `Maybe` when dealing with complex operations that can fail.

```elm
if Maybe.isJust selectedUser then
	process selectedUser -- ❌
else
	default
...
process : Maybe User -> ...
```

```elm
case selectedUser of
	Just user ->
		process user -- ✅ no `Maybe` anymore!
	Nothing ->
		default
...
process : User -> ...
```

### Don't fear custom types

For example, one could be tempted to create some user type looking like this:

```elm
type alias User =
	{ name : String
	, isPremium : Bool -- Users can be Premium or Free
	}
```

and that would be just fine for the moment. However, if you ever need to expand the `User` type in the future, things will become harder to refactor the more the type grows. So, don't fear to create a type with only two constructors:

```elm
type UserPlan
	= Premium
	| Free

type alias User =
	{ name : String
	, plan : UserPlan
	}
```

This will make your code more readable and easier to refactor in the future.

### Make impossible states impossible

> If something can be done, it will be done eventually

Try to define your types in a way that makes it impossible to have invalid states. For example, to keep track if some data is waiting to be fetched you could define your model like this:

```elm
type alias Model =
	{ isLoading : Bool
	, userNames : List String
	}
```

With this we check if `userNames` have been fetched. If not, we set `isLoading` to `True` -which shows a spinner- and wait for the server response. Once we have the data, we fill `userNames` with it and set `isLoading` to `False` again to stop showing the spinner. Flaw here is that we could have `isLoading` to `True` with the `userNames` list filled and it'd be a perfect valid state. And of course this is bad, because the spinner would be showing forever.

There are several ways to improve this type to make it follow the rule. One of them is the use of the [RemoteData](https://package.elm-lang.org/packages/krisajenkins/remotedata/latest/) library, which ensures you'll never forget about the different states of an HTTP request. With it we can set the new type as:

```elm
type RemoteData e a
	= NotAsked
	| Loading
	| Failure e
	| Success a

type alias Model =
	{ remoteUserNames : RemoteData customError (List String) }
```

and there's no way to have invalid states anymore.

### Avoid excessive obfuscation

Pointfree functions and composition are cool, but don't overuse them. Most of the time a lambda function is better inside a pipeline than 3-4 right composed `>>` functions. Also, prefer `|>` over `<|`, parens over `<|`, and 2-3 functions instead of a big `foldl` or `foldr`.

### Parse, don't validate

Decode data to it's highest level possible. Use Elm's type system to your favor. See: [Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/).

### Use opaque identifiers

Don’t use simple types or type aliases for identifiers. Creating a custom type instead enables the compiler to find bugs (like passing a user id to a function that should take an location id) at compile time, not in production.

For example, do:

```elm
type UserId
    = UserId String
```

Not:

```elm
type alias UserId =
    String
```

If you need a `Dict` or `Set` with `StudentId` as keys, use [any-dict](https://package.elm-lang.org/packages/turboMaCk/any-dict/latest/Dict-Any) & [any-set](https://package.elm-lang.org/packages/turboMaCk/any-set/latest/Set.Any) instead of the core implementations.

### Stick to Domain-Driven Design

Try to make the functions related to a type to reside inside its own module.
Do:

```elm
module User exposing (toString)
...
toString : User -> String
toString user =
...
```

```elm
module Location exposing (toString)
...
toString : Location -> String
toString location =
...
```

Instead of:

```elm
module Data exposing (toString)
...
userToString : User -> String
userToString user =
...
locationToString : Location -> String
locationToString location =
...
```

### Wrap Early, Unwrap Late

Keep your values as close to reality as you can, the sooner the better. Make them stay like that in the whole program flow.
Only unwrap them into unsafe values at the very last moment.

## More Resources

See **Martin Janiczek's [Elm best practices.pdf](https://globalwebindex.slack.com/files/UC8QW9BCG/F038G666891/elm_best_practices.pdf)**.
