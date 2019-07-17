with STM32F7_Disco.Ethernet_Comunication;

package Protected_Object_Movement is

   protected type Movement is
      procedure Set_Move (M : in STM32F7_Disco.Ethernet_Comunication.Message_Type);
      entry Get_Move (M : out STM32F7_Disco.Ethernet_Comunication.Message_Type);
   private
      Has_Changed : Boolean := False;
      Next_Move : STM32F7_Disco.Ethernet_Comunication.Message_Type;
   end Movement;

end Protected_Object_Movement;
