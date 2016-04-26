# VSTS Trigger

The extension contains tasks which allow to trigger processes.

## How it works
The task calls VSTS REST API for triggering process and fetching all needed parameters. For it you need to add Endpoint Service.
* First of it you need to add Personal access token to your VSTS. You need to open **My profile** -> **Security** tab -> **Personal access tokens** and press Add button

> Note:
> For start release is enough to have scope "Release (read, write and execute)", but in our case we use API for getting latest atrifacts for target release (the API is out of scopes all scope), that is why we need to choose "All scopes"

## ReleaseTrigger

The task allow to trigger release process from build process or other release process. The task builds batch with all needed artifacts with latest versions for target release definition and trigger the release. In case when target release definition needs artifact from current process the task takes current artifacts, not latest.
