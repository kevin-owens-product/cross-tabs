# Web Accessibility

Web accessibility, or eAccessibility, is the inclusive practice of ensuring there are no barriers that prevent
interaction with, or access to, websites on the World Wide Web by people with physical disabilities, situational disabilities,
and socio-economic restrictions on bandwidth and speed. (Wikipedia)

# Web Accessibility in Crosstabs

What we are basically looking for is to be able to access all functions using only our keyboard.

How are we going to do this? first of all by applying a `Visual Style`, following these guidelines:

1. Figma file - Hover and focus states: https://www.figma.com/file/rPE5A9WLANfI1pGvXwIlxD/Accessibility-fixes?node-id=0%3A1
2. Anything missing should be in Dottie or if not, we should use a 2px outline Dark pink.

Now let's see how to use the `DOM FOCUS`
usually the focus is done automatically depending on how the html is loaded and placed.
But sometimes when an event is triggered we may want to modify the focus (for example when opening a modal or a menu).

# How to do it?

1. Case of normal accessibility:
   we use a focus-visible property in the css code
   example:

    ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/a04ea684-52df-4886-a1fb-9dad1e2f3eb5)

    Somethimes in Crosstabs we want to apply the style to an element when it is another element that is in focus.
    For that we will use:

    ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/a1d91be9-2100-41be-859a-be2fffcd8036)

2. Modify Focus on Events

    We have to add a id to the html element we whant to focus in crosstabs we can use the Attrs.id in the view:

    ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/834388d3-d42d-4219-a9ff-fe3cdd8fd5a2)

    Now let's go to the Event to add a Cmd:

    ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/63f5debb-8138-4ddd-bfcd-2125290ff4a4)

# Potential problems

In rare cases the modal needs to load data and the focus has no effect, so we need to delay the Cmd.
![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/135aaba8-ac15-4b60-ab2a-35dca5c78d16)
