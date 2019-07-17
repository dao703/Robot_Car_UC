with STM32F7_Disco.Ethernet_Comunication;

package body Protected_Object_Movement is

   protected body Movement is
      procedure Set_Move (M : in STM32F7_Disco.Ethernet_Comunication.Message_Type) is
      begin
         Has_Changed := True;
         Next_Move := M;
      end Set_Move;

      entry Get_Move (M : out STM32F7_Disco.Ethernet_Comunication.Message_Type) when Has_Changed is
      begin
         Has_Changed := False;
         M := Next_Move;
         Next_Move := "00000000000000000000000000000000000000000000000000";
      end Get_Move;

   end Movement;

end Protected_Object_Movement;
