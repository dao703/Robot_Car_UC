with System;

package Remote_Control_Car_Tasks is


   procedure Start;

   task Trasnmitter_Task with
     Priority => System.Default_Priority - 10;

   task Receiver_Task with
     Priority => System.Default_Priority - 10;

   task Check_Display with
     Priority => System.Default_Priority - 5;

   task  Orientation_Task with
     Priority => System.Default_Priority - 10;

end Remote_Control_Car_Tasks;
