# How to use this

1. Manually create subscription with GA account
2. With the name you used, add this to $subscriptionId inside `Management-Prep.ps1`
3. Run `Management-Prep.ps1`
4. Manually add the service principle and managed identity to Billing Contributor on the portal
4. Assign the service principle generated in the Management-Prep.ps1 or create a new one for more restricted access and assign the following Microsoft.Graph permissions manually in the portal:
   The following:

   - Application.ReadWrite.All
   - AppRoleAssignment.ReadWrite.All
   - Group.ReadWrite.All
   - Directory.ReadWrite.All
   - RoleManagement.ReadWrite.Directory

5. You may now run the Assign-GraphPermissions.ps1 (may need to run it twice, one for service principle and one for managed id)
6. Using details generated during `Management-Prep.ps1`, run the terraform build
