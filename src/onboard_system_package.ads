with System;

package Onboard_System_Package is

   procedure Start;

   task Onborad_Task with
   Priority => System.Default_Priority - 1;

end Onboard_System_Package;
