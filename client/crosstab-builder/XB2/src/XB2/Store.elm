module XB2.Store exposing
    ( Config
    , DuplicateParams
    , Msg(..)
    , Store
    , copyOfXBProject
    , createXBFolder
    , createXBProject
    , destroyXBFolder
    , destroyXBFolderWithContent
    , destroyXBProject
    , duplicateXBProject
    , fetchTaskXBProjectFullyLoaded
    , fetchXBFolders
    , fetchXBProject
    , fetchXBProjectById
    , fetchXBProjectList
    , fetchXBUserSettings
    , folderNameExists
    , getAllProjectNames
    , init
    , moveProjectsToFolder
    , projectNameExists
    , removeOrUnshareXBProjects
    , renameXBFolder
    , renameXBProject
    , setDoNotShowAgain
    , setFolderXBProject
    , setSharedProjectWarningDismissal
    , setXB2ListFTUESeen
    , shareXBProject
    , shareXBProjectWithLink
    , unshareMe
    , update
    , updateXBProject
    , updateXBUserSettings
    )

import Cmd.Extra as Cmd
import Dict.Any
import Glue
import Maybe.Extra as Maybe
import RemoteData exposing (RemoteData(..), WebData)
import Result.Extra as Result
import Task exposing (Task)
import XB2.Data as Data
    exposing
        ( XBFolder
        , XBFolderId
        , XBFolderIdTag
        , XBProject
        , XBProjectError
        , XBProjectFullyLoaded
        , XBProjectId
        , XBProjectIdTag
        , XBUserSettings
        )
import XB2.Share.Config exposing (Flags)
import XB2.Share.Data.Id exposing (IdDict)
import XB2.Share.Gwi.Http exposing (Error)
import XB2.Share.Store.Utils as Store


type alias DuplicateParams =
    { original : XBProject
    , duplicate : XBProject
    , shouldRedirect : Bool
    }


type Msg msg
    = AjaxError (Store -> Store) (Error Never)
    | ProjectAjaxError (Store -> Store) (Error XBProjectError)
    | XBProjectsFetched (List XBProject)
    | XBProjectFetched XBProject
    | XBProjectDestroyed XBProjectFullyLoaded
    | XBProjectCreated (List (XBProject -> Cmd msg)) XBProject
    | XBProjectUpdated XBProject
    | XBProjectRenamed XBProject
    | XBProjectFolderSet { project : XBProject, oldFolderId : Maybe XBFolderId }
    | XBProjectsMovedToFolder { oldFolderId : Maybe XBFolderId, projects : List XBProject, folderId : Maybe XBFolderId }
    | XBProjectsDestroyedAndUnshared (List XBProject)
    | XBProjectDuplicated DuplicateParams
    | XBProjectShared XBProject
    | XBProjectSharedWithLink XBProject
    | XBFoldersFetched (List XBFolder)
    | XBFolderCreated (List XBProject) XBFolder
    | XBFolderRenamed XBFolder
    | XBFolderWithContentDestroyed XBFolder (List XBProject)
    | XBFolderDestroyed XBFolder (List XBProject)
    | XBUserSettingsFetched XBUserSettings
    | XBUserSettingsUpdated XBUserSettings
    | XBUserSettingsUpdatedDoNotSave
    | XBProjectUnshared XBProject


type alias Config msg =
    { msg : Msg msg -> msg
    , err : Error Never -> msg
    , projectErr : Error XBProjectError -> msg
    }


type alias Store =
    { xbProjects : WebData (IdDict XBProjectIdTag XBProject)
    , xbFolders : WebData (IdDict XBFolderIdTag XBFolder)
    , userSettings : WebData XBUserSettings
    }


init : Store
init =
    { xbProjects = NotAsked
    , xbFolders = NotAsked
    , userSettings = NotAsked
    }


update : Config msg -> Msg msg -> Store -> ( Store, Cmd msg )
update config msg store =
    let
        newProject xbProject =
            ( { store | xbProjects = Store.insertResource store.xbProjects xbProject }
            , Cmd.none
            )

        updateProject xbProject =
            ( { store | xbProjects = Store.insertResource store.xbProjects xbProject }
            , Cmd.none
            )

        setFtueSeenIfNeeded store_ =
            if RemoteData.unwrap False .xb2ListFTUESeen store_.userSettings then
                Cmd.pure store_

            else
                { store_
                    | userSettings =
                        store_.userSettings
                            |> RemoteData.map
                                (\settings ->
                                    { settings | xb2ListFTUESeen = True }
                                )
                }
                    |> Cmd.pure
    in
    case msg of
        AjaxError setStore err ->
            Cmd.withTrigger
                (config.err err)
                (setStore store)

        ProjectAjaxError setStore err ->
            Cmd.withTrigger
                (config.projectErr err)
                (setStore store)

        XBProjectsFetched xbProjects ->
            ( { store | xbProjects = Store.taggedCollectionLoaded xbProjects }
            , Cmd.none
            )

        XBProjectFetched xbProject ->
            updateProject xbProject

        XBProjectDestroyed { id } ->
            ( { store | xbProjects = Store.removeResource store.xbProjects id }
            , Cmd.none
            )

        XBProjectCreated finishCallbacks xbProject ->
            newProject xbProject
                |> Cmd.add
                    (List.foldl
                        (\fn acc ->
                            Cmd.batch [ fn xbProject, acc ]
                        )
                        Cmd.none
                        finishCallbacks
                    )
                |> Glue.updateWith Glue.id setFtueSeenIfNeeded

        XBProjectDuplicated { duplicate } ->
            newProject duplicate

        XBProjectUpdated xbProject ->
            updateProject xbProject

        XBProjectRenamed xbProject ->
            updateProject xbProject

        XBProjectShared xbProject ->
            updateProject xbProject

        XBProjectSharedWithLink xbProject ->
            updateProject xbProject

        XBProjectFolderSet { project } ->
            updateProject project

        XBProjectsMovedToFolder { projects } ->
            projects
                |> List.foldl
                    (\xbProject ->
                        Glue.updateWith Glue.id
                            (\currentStore ->
                                ( { currentStore | xbProjects = Store.insertResource currentStore.xbProjects xbProject }
                                , Cmd.none
                                )
                            )
                    )
                    (Cmd.pure store)

        XBProjectsDestroyedAndUnshared projects ->
            projects
                |> List.foldl
                    (\{ id } ->
                        Glue.updateWith Glue.id
                            (\currentStore ->
                                ( { currentStore | xbProjects = Store.removeResource currentStore.xbProjects id }
                                , Cmd.none
                                )
                            )
                    )
                    (Cmd.pure store)

        XBFoldersFetched xbFolders ->
            ( { store | xbFolders = Store.taggedCollectionLoaded xbFolders }
            , Cmd.none
            )

        XBFolderCreated _ xbFolder ->
            ( { store | xbFolders = Store.insertResource store.xbFolders xbFolder }
            , Cmd.none
            )

        XBFolderRenamed xbFolder ->
            ( { store | xbFolders = Store.insertResource store.xbFolders xbFolder }
            , Cmd.none
            )

        XBFolderWithContentDestroyed { id } _ ->
            ( { store
                | xbFolders = Store.removeResource store.xbFolders id
                , xbProjects =
                    store.xbProjects
                        |> Store.filterResource
                            (\_ { folderId } ->
                                Just id /= folderId
                            )
              }
            , Cmd.none
            )

        XBFolderDestroyed { id } _ ->
            ( { store
                | xbFolders = Store.removeResource store.xbFolders id
                , xbProjects =
                    store.xbProjects
                        |> RemoteData.map
                            (Dict.Any.map
                                (\_ project ->
                                    if project.folderId == Just id then
                                        { project | folderId = Nothing }

                                    else
                                        project
                                )
                            )
              }
            , Cmd.none
            )

        XBUserSettingsFetched settings ->
            ( { store | userSettings = Success settings }
            , Cmd.none
            )

        XBUserSettingsUpdated settings ->
            ( { store | userSettings = Success settings }
            , Cmd.none
            )

        XBUserSettingsUpdatedDoNotSave ->
            ( store, Cmd.none )

        XBProjectUnshared xbProject ->
            ( { store | xbProjects = Store.removeResource store.xbProjects xbProject.id }
            , Cmd.none
            )


fetchXBProjectList : Config msg -> Flags -> Store -> ( Store, Cmd msg )
fetchXBProjectList { msg } =
    Store.peek
        Data.xbProjectErrorToHttpError
        .xbProjects
        (msg << XBProjectsFetched)
        (\set -> msg << ProjectAjaxError set)
        Data.fetchXBProjectList
        (\store ->
            Maybe.unwrap { store | xbProjects = Loading }
                (\e -> { store | xbProjects = Failure e })
        )


fetchXBProject : Config msg -> XBProject -> Flags -> Store -> ( Store, Cmd msg )
fetchXBProject { msg } project =
    let
        getState : Store -> WebData Data.XBProjectData
        getState { xbProjects } =
            Store.get xbProjects project.id
                |> Maybe.unwrap NotAsked .data

        insertProject store data =
            { store | xbProjects = Store.insertResource store.xbProjects { project | data = data } }
    in
    (\store ->
        Maybe.unwrap
            (insertProject store Loading)
            (insertProject store << Failure)
    )
        |> Store.peek
            Data.xbProjectErrorToHttpError
            getState
            (msg << XBProjectFetched)
            (\set -> msg << ProjectAjaxError set)
            (Data.fetchXBProject project.id)


fetchXBProjectById : Config msg -> XBProjectId -> Flags -> Store -> ( Store, Cmd msg )
fetchXBProjectById { msg } projectId =
    let
        getState : Store -> WebData Data.XBProjectData
        getState { xbProjects } =
            Store.get xbProjects projectId
                |> Maybe.unwrap NotAsked .data
    in
    (\store -> always store)
        |> Store.peek
            Data.xbProjectErrorToHttpError
            getState
            (msg << XBProjectFetched)
            (\set -> msg << ProjectAjaxError set)
            (Data.fetchXBProject projectId)


fetchXBUserSettings : Config msg -> Flags -> Store -> ( Store, Cmd msg )
fetchXBUserSettings { msg } =
    let
        insertUserSettings store data =
            { store | userSettings = data }
    in
    Store.peek
        never
        .userSettings
        (msg << XBUserSettingsFetched)
        (\set -> msg << AjaxError set)
        Data.fetchXBUserSettings
        (\store ->
            Maybe.unwrap
                (insertUserSettings store Loading)
                (insertUserSettings store << Failure)
        )


updateXBUserSettings : XBUserSettings -> Config msg -> Flags -> Store -> ( Store, Cmd msg )
updateXBUserSettings newSettings { msg } flags store =
    ( { store | userSettings = Success newSettings }
    , let
        httpResultToMsg =
            Result.unpack
                -- rollback the optimistic update on error
                (msg << AjaxError (\store_ -> { store_ | userSettings = store.userSettings }))
                (msg << XBUserSettingsUpdated)
      in
      Cmd.map httpResultToMsg <| Data.updateXBUserSettings newSettings flags
    )


setSharedProjectWarningDismissal : Bool -> Config msg -> Flags -> Store -> ( Store, Cmd msg )
setSharedProjectWarningDismissal shouldDismiss config flags ({ userSettings } as store) =
    userSettings
        |> RemoteData.map
            (\settings ->
                if settings.canShowSharedProjectWarning == not shouldDismiss then
                    {- This request would do nothing, so let's ignore it.

                       This can happen because of the Msg firing twice :( - see
                       `XB.Header.checkboxView` and the TODO inside
                    -}
                    ( store, Cmd.none )

                else
                    let
                        newSettings =
                            { settings | canShowSharedProjectWarning = not shouldDismiss }
                    in
                    updateXBUserSettings newSettings config flags store
            )
        |> RemoteData.withDefault ( store, Cmd.none )


setDoNotShowAgain : Data.DoNotShowAgain -> Config msg -> Flags -> Store -> ( Store, Cmd msg )
setDoNotShowAgain doNotShowAgain config flags ({ userSettings } as store) =
    userSettings
        |> RemoteData.map
            (\settings ->
                if Data.canShow doNotShowAgain settings then
                    let
                        newSettings =
                            { settings | doNotShowAgain = doNotShowAgain :: settings.doNotShowAgain }
                    in
                    updateXBUserSettings newSettings config flags store

                else
                    ( store, Cmd.none )
            )
        |> RemoteData.withDefault ( store, Cmd.none )


{-| Warning: this behaves differently from other Cmds here.
Others:

  - save flag optimistically locally
  - send request to change it to BE
  - get result from BE and save it again (should be the same as the optimistic one)
    This function:
  - send request to change it to BE
  - get result from BE and _don't_ save it.
    This is to not hide the FTUE for the user the first (and only) time they are
    supposed to see it. Imagine: `update` would send the Cmd to set the flag, `view`
    would show the FTUE, the Cmd would come back, `update` would set the flag, `view`
    would hide the FTUE. So we intentionally ignore the confirmation coming back
    from BE.
    We don't care much about other XBUserSettings-related functions overwriting this
    one though. At that point user has probably seen the FTUE, interacted with the XB
    in some way, and it's fine if we hide it then.
    Another way to do this would be to have a field inside `Model` that keeps the
    FTUE alive for the current session, even though the XBUserSettings have changed
    in the meantime.

-}
setXB2ListFTUESeen : Config msg -> Flags -> Store -> ( Store, Cmd msg )
setXB2ListFTUESeen { msg } flags ({ userSettings } as store) =
    userSettings
        |> RemoteData.map
            (\settings ->
                if settings.xb2ListFTUESeen then
                    ( store, Cmd.none )

                else
                    ( -- DON'T SAVE THE NEW SETTINGS IN THE STORE!
                      store
                    , let
                        newSettings =
                            { settings | xb2ListFTUESeen = True }

                        httpResultToMsg =
                            Result.unpack
                                -- no need to rollback
                                (msg << AjaxError identity)
                                -- DON'T SAVE!
                                (always <| msg XBUserSettingsUpdatedDoNotSave)
                      in
                      Cmd.map httpResultToMsg <| Data.updateXBUserSettings newSettings flags
                    )
            )
        |> RemoteData.withDefault ( store, Cmd.none )


fetchTaskXBProjectFullyLoaded : XBProject -> Flags -> Task (Error XBProjectError) XBProjectFullyLoaded
fetchTaskXBProjectFullyLoaded project flags =
    case Data.getFullyLoadedProject project of
        Just fullyLoadedProject ->
            Task.succeed fullyLoadedProject

        Nothing ->
            Data.fetchTaskXBProjectFullyLoaded project flags


createXBProject :
    Maybe XBFolderId
    -> List (XBProject -> Cmd msg)
    -> Config msg
    -> XBProjectFullyLoaded
    -> Flags
    -> Store
    -> ( Store, Cmd msg )
createXBProject currentFolderId finishCallbacks { msg } projectFull =
    let
        project : XBProject
        project =
            Data.fullyLoadedToProject projectFull

        projectWithFolderId : XBProject
        projectWithFolderId =
            { project | folderId = currentFolderId }
    in
    Store.modify
        .xbProjects
        (msg << XBProjectCreated finishCallbacks)
        (msg << ProjectAjaxError identity)
        Data.createXBProject
        projectWithFolderId
        identity


updateXBProject : Config msg -> XBProjectFullyLoaded -> Flags -> Store -> ( Store, Cmd msg )
updateXBProject { msg } newProjectFull =
    let
        newProject =
            Data.fullyLoadedToProject newProjectFull
    in
    if Data.isSharedWithMe newProject.shared then
        \_ store ->
            store
                |> Cmd.withTrigger (msg <| ProjectAjaxError identity <| XB2.Share.Gwi.Http.CustomError "" "" Data.DifferentOwner)

    else
        Store.modify
            .xbProjects
            (msg << XBProjectUpdated)
            (msg << ProjectAjaxError identity)
            Data.updateXBProject
            newProject
            identity


patchXBProject : (XBProject -> Msg msg) -> Config msg -> XBProject -> Flags -> Store -> ( Store, Cmd msg )
patchXBProject toMsg { msg } newProject =
    if Data.isSharedWithMe newProject.shared then
        \_ store ->
            store
                |> Cmd.withTrigger (msg <| ProjectAjaxError identity <| XB2.Share.Gwi.Http.CustomError "" "" Data.DifferentOwner)

    else
        Store.modify
            .xbProjects
            (msg << toMsg)
            (msg << ProjectAjaxError identity)
            Data.patchXBProject
            newProject
            identity


renameXBProject : Config msg -> XBProject -> Flags -> Store -> ( Store, Cmd msg )
renameXBProject =
    patchXBProject XBProjectRenamed


shareXBProject : Config msg -> XBProject -> Flags -> Store -> ( Store, Cmd msg )
shareXBProject =
    patchXBProject XBProjectShared


shareXBProjectWithLink : Config msg -> XBProject -> Flags -> Store -> ( Store, Cmd msg )
shareXBProjectWithLink { msg } xbProject =
    if Data.isSharedWithMe xbProject.shared then
        \_ store ->
            store
                |> Cmd.withTrigger (msg <| ProjectAjaxError identity <| XB2.Share.Gwi.Http.CustomError "" "" Data.DifferentOwner)

    else
        Store.modify
            .xbProjects
            (always <| msg <| XBProjectSharedWithLink xbProject)
            (msg << ProjectAjaxError identity)
            Data.shareXBProjectWithLink
            xbProject
            identity


setFolderXBProject : { oldFolderId : Maybe XBFolderId } -> Config msg -> XBProject -> Flags -> Store -> ( Store, Cmd msg )
setFolderXBProject { oldFolderId } =
    patchXBProject
        (\project ->
            XBProjectFolderSet
                { oldFolderId = oldFolderId
                , project = project
                }
        )


moveProjectsToFolder : Maybe XBFolderId -> Config msg -> List XBProject -> Flags -> Store -> ( Store, Cmd msg )
moveProjectsToFolder folderId config projects flags store =
    ( store
    , Task.sequence (List.map (\p -> Data.patchXBProjectTask { p | folderId = folderId } flags) projects)
        |> Task.attempt
            (\result ->
                config.msg <|
                    case result of
                        Ok xbProjects ->
                            let
                                oldFolderId =
                                    List.head projects
                                        |> Maybe.andThen .folderId
                            in
                            XBProjectsMovedToFolder { oldFolderId = oldFolderId, projects = xbProjects, folderId = folderId }

                        Err err ->
                            ProjectAjaxError identity err
            )
    )


removeOrUnshareXBProjects : Config msg -> List XBProject -> Flags -> Store -> ( Store, Cmd msg )
removeOrUnshareXBProjects config projects flags store =
    let
        ( projectsToUnshare, projectsToDestroy ) =
            List.partition (Data.isSharedWithMe << .shared) projects
    in
    ( store
    , (List.map (\p -> Data.destroyXBProjectTask p flags) projectsToDestroy
        ++ List.map (\p -> Data.unshareMeTask p flags) projectsToUnshare
      )
        |> List.foldr
            (\task ->
                Task.andThen
                    (\( okSoFar, errorsSoFar ) ->
                        task
                            |> Task.map (\xbProject -> ( xbProject :: okSoFar, errorsSoFar ))
                            |> Task.onError (\err -> Task.succeed ( okSoFar, err :: errorsSoFar ))
                    )
            )
            (Task.succeed ( [], [] ))
        |> Task.map
            (\( xbProjects, errors ) ->
                let
                    removeFromStoreOnError store_ =
                        { store_
                            | xbProjects =
                                xbProjects
                                    |> List.foldl
                                        (\{ id } currentProjects ->
                                            Store.removeResource currentProjects id
                                        )
                                        store_.xbProjects
                        }
                in
                config.msg <|
                    case errors of
                        [] ->
                            XBProjectsDestroyedAndUnshared xbProjects

                        err :: _ ->
                            ProjectAjaxError removeFromStoreOnError err
            )
        |> Task.attempt
            (\result ->
                case result of
                    Ok msg ->
                        msg

                    Err err ->
                        config.msg <| ProjectAjaxError identity err
            )
    )


unshareMe : Config msg -> XBProject -> Flags -> Store -> ( Store, Cmd msg )
unshareMe { msg } project =
    Store.destroy
        .xbProjects
        (always <| msg <| XBProjectUnshared project)
        (msg << AjaxError identity)
        Data.unshareMe
        project
        identity


duplicateXBProject :
    Config msg
    ->
        { newName : String
        , originalProject : XBProjectFullyLoaded
        }
    -> Flags
    -> Store
    -> ( Store, Cmd msg )
duplicateXBProject { msg } { newName, originalProject } =
    let
        originalProject_ =
            Data.fullyLoadedToProject originalProject

        project =
            { originalProject_
                | id = XB2.Share.Data.Id.fromString ""
                , name = newName
                , shared = Data.MyPrivateCrosstab
                , sharingNote = ""
            }
    in
    Store.modify
        .xbProjects
        (\newProject ->
            msg <|
                XBProjectDuplicated
                    { original = originalProject_
                    , duplicate = newProject
                    , shouldRedirect = False
                    }
        )
        (msg << ProjectAjaxError identity)
        Data.createXBProject
        project
        identity


copyOfXBProject :
    Config msg
    ->
        { copy : XBProjectFullyLoaded
        , original : XBProjectFullyLoaded
        , shouldRedirect : Bool
        }
    -> Flags
    -> Store
    -> ( Store, Cmd msg )
copyOfXBProject { msg } { copy, original, shouldRedirect } =
    let
        originalProject_ =
            Data.fullyLoadedToProject original

        project =
            Data.fullyLoadedToProject copy
    in
    Store.modify
        .xbProjects
        (\newProject ->
            msg <|
                XBProjectDuplicated
                    { original = originalProject_
                    , duplicate = newProject
                    , shouldRedirect = shouldRedirect
                    }
        )
        (msg << ProjectAjaxError identity)
        Data.createXBProject
        project
        identity


destroyXBProject : Config msg -> XBProjectFullyLoaded -> Flags -> Store -> ( Store, Cmd msg )
destroyXBProject { msg } projectFull =
    Store.destroy
        .xbProjects
        (always <| msg <| XBProjectDestroyed projectFull)
        (msg << ProjectAjaxError identity)
        Data.destroyXBProject
        (Data.fullyLoadedToProject projectFull)
        identity


fetchXBFolders : Config msg -> Flags -> Store -> ( Store, Cmd msg )
fetchXBFolders { msg } =
    Store.peek
        never
        .xbFolders
        (msg << XBFoldersFetched)
        (\set -> msg << AjaxError set)
        Data.fetchXBFolders
        (\store ->
            Maybe.unwrap { store | xbFolders = Loading }
                (\e -> { store | xbFolders = Failure e })
        )


createXBFolder : Config msg -> List XBProject -> XBFolder -> Flags -> Store -> ( Store, Cmd msg )
createXBFolder { msg, err } projects folder =
    Store.modify
        .xbFolders
        (msg << XBFolderCreated projects)
        err
        Data.createXBFolder
        folder
        identity


renameXBFolder : Config msg -> XBFolder -> Flags -> Store -> ( Store, Cmd msg )
renameXBFolder { msg, err } newFolder =
    Store.modify
        .xbFolders
        (msg << XBFolderRenamed)
        err
        Data.renameXBFolder
        newFolder
        identity


destroyXBFolderWithContent : Config msg -> XBFolder -> Flags -> Store -> ( Store, Cmd msg )
destroyXBFolderWithContent { msg, err } folderToDestroy flags store =
    let
        projectsInFolder =
            store.xbProjects
                |> Store.filterResource
                    (\_ { folderId } ->
                        Just folderToDestroy.id == folderId
                    )
                |> RemoteData.toMaybe
                |> Maybe.unwrap [] Dict.Any.values
    in
    Store.destroy
        .xbFolders
        (always <| msg <| XBFolderWithContentDestroyed folderToDestroy projectsInFolder)
        err
        Data.destroyXBFolderWithContent
        folderToDestroy
        identity
        flags
        store


destroyXBFolder : Config msg -> XBFolder -> Flags -> Store -> ( Store, Cmd msg )
destroyXBFolder { msg, err } folderToDestroy flags store =
    let
        projectsInFolder =
            store.xbProjects
                |> Store.filterResource
                    (\_ { folderId } ->
                        Just folderToDestroy.id == folderId
                    )
                |> RemoteData.toMaybe
                |> Maybe.unwrap [] Dict.Any.values
    in
    Store.destroy
        .xbFolders
        (always <| msg <| XBFolderDestroyed folderToDestroy projectsInFolder)
        err
        Data.destroyXBFolder
        folderToDestroy
        identity
        flags
        store


projectNameExists : Store -> String -> Bool
projectNameExists xbStore newName =
    xbStore.xbProjects
        |> RemoteData.unwrap False (Dict.Any.values >> List.any (.name >> (==) newName))


getAllProjectNames : Store -> List String
getAllProjectNames xbStore =
    xbStore.xbProjects
        |> RemoteData.unwrap [] (Dict.Any.values >> List.map .name)


folderNameExists : Store -> String -> Bool
folderNameExists xbStore newName =
    xbStore.xbFolders
        |> RemoteData.unwrap False (Dict.Any.values >> List.any (.name >> (==) newName))
