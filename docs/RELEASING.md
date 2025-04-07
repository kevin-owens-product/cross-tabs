# Releasing pro-next to production

## The process

-   JIRA: check for release blockers
-   let folks test and merge

:warning: These steps need to happen "atomically" - as close to each other as possible:

-   ```bash
    git checkout master
    git pull
    ```
-   JIRA: [create a release](https://globalwebindex.atlassian.net/projects/AUR?selectedItem=com.atlassian.jira.jira-projects-plugin%3Arelease-page) by clicking on "Create version" button.
-   JIRA: Check the last version released
-   ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/05bf72bd-7e6d-453a-9830-120bd88990e0)
-   JIRA: Create a new version (based on the last version + 1)
-   ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/2a44686a-1ab9-4418-a10f-98c814db698b)

(End of the "atomic" step.)

-   ```bash
    git checkout production
    git pull
    git merge master --no-ff
    git tag X.Y.Z
    git push && git push --tags
    ```

-   GITHUB: Create a new release

    ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/d45ae19b-c5ad-4c20-a428-a6e050627e98)
    - Choose the correct tag and use the tag name in the title ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/8832e170-bf44-4ae9-973d-99ca5937297e)
    - Now for the description come back to JIRA, click on the release and release notes
    - Copy the text here and use it for the release description : ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/a117bb77-99f4-49c1-998c-74406d46f019)
    - Publish the release
-   Slack: write the announcement in `#squad-aurora` (see the previous release announcements for template)
-   Pat yourself on the back, the release is DONE! Now the ball is on the PMs side of court. 🏓

⏳ ... PMs activate the release ...

-   JIRA: [release the release](https://globalwebindex.atlassian.net/projects/ATC?selectedItem=com.atlassian.jira.jira-projects-plugin%3Arelease-page)
-   JIRA [AUTOMATION]: Mass transition to Done. [Manual check if needed](<https://globalwebindex.atlassian.net/issues/?jql=project%20%3D%20ATC%20AND%20labels%20in%20(FE)%20AND%20Sprint%20%3D%20484%20AND%20status%20%3D%20Deploy%20AND%20flagged%20is%20EMPTY>)

## How the deployment is done

Required:

-   You need to do a release before
-   You also need the VPN connection
-   In the tag version of the last release, copy the last commit SHA (NOT THE MERGE ONE!) ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/f5d61904-d0d8-41e0-a849-0fb186011a2d) > ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/6dba477a-c9d5-413f-9cdd-198eedf7d0d1)

Deploy on staging:

-   To deploy on staging
-   Go to the next URL : https://fe-configuration-staging.in.globalwebindex.com/
-   Click on the Microfrontend of platform 2
-   Now for each one of our application (Crosstab and tv-rf) do the next step
-   Click on update version of each appli
-   Copy the SHA inside and click update ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/6b659c31-fa3f-4013-8daf-3ab2d4a861e7)
-   Now you can test your changes on: https://app-staging.globalwebindex.com/

Deploy on production:

-   To deploy on staging
-   Go to the next URL : https://fe-configuration.in.globalwebindex.com/
-   Click on the Microfrontend of platform 2
-   Now for each one of our application (Crosstab and tv-rf) do the next step
-   Click on update version of each appli
-   Go to Feature Branches, select elm-release and copy the SHA inside, click on Bind ![image](https://github.com/GlobalWebIndex/pro-next/assets/39096665/ab432744-8147-43bf-99ee-e787da00eb2a)
-   Now you can test your changes on: https://app.globalwebindex.com/elm-release

## E2E tests
-    It is necessary to run these tests before making the official release to production.
-    First of all, go to the github gwi-platform-ta in the actions window: https://github.com/GlobalWebIndex/gwi-platform-ta/actions 
-    Now select the manual_sta workflow and run a new workflow.
-    Make sure you select the correct environment and branch.
-    Add the route cypress/e2e/Crosstabs
-    Run it! 🤪
-    ![image](https://github.com/user-attachments/assets/98540bdd-2733-4120-81ee-b117f8e6894c)

