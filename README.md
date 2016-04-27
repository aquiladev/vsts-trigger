# VSTS Trigger

The extension contains tasks which allow to trigger processes.

## How it works
The task calls VSTS REST API for triggering process and fetching all needed data.

## Getting started
* First of all you need to add Personal access token to your VSTS. You need to open **My profile** -> **Security** tab -> **Personal access tokens** and click Add button.
![Personal access tokens](https://raw.githubusercontent.com/aquiladev/vsts-trigger/master/Extension/Images/add_personal_token.png)

> Note:
> For starting release is enough to have scope "Release (read, write and execute)", but in our case we use API for getting latest atrifacts for target release (the API is out of all presented scopes), that is why we need to choose "All scopes" - TEMPORARY SOLUTION

* Than you need to add Generic Endpoint Service
![Generic Endpoint Service](https://raw.githubusercontent.com/aquiladev/vsts-trigger/master/Extension/Images/add_service_start.png)

Use generated personal access token, Server URL is your VSTS service, User name can be anything
![Generic Endpoint Service](https://raw.githubusercontent.com/aquiladev/vsts-trigger/master/Extension/Images/add_service.png)

## ReleaseTrigger task

The task allow to trigger release process from build process or other release process. The task builds batch with all needed artifacts with latest versions for target release definition and trigger the release. In case when target release definition needs artifact from current process the task takes current artifacts, not latest.

To add task into your build or release definition
![Add Task](https://raw.githubusercontent.com/aquiladev/vsts-trigger/master/Extension/Images/add_task.png)

fill settings for the task
![Task](https://raw.githubusercontent.com/aquiladev/vsts-trigger/master/Extension/Images/task.png)
