
with Net.Buffers;                       use Net.Buffers;
with Interfaces;                        use Interfaces;
with Net.Interfaces.STM32;              use Net.Interfaces.STM32;
with STM32.SDRAM;
with Net.Headers;

with Net;  use Net;
with STM32.RNG.Interrupts;

with Net.Headers;                       use Net.Headers;
with Net.Buffers;
with Net; use Net;
with Net.Buffers;


package STM32F7_Disco.Ethernet_Comunication is

   subtype Message_Type is String (1 .. 50);
   NET_BUFFER_SIZE : constant Net.Uint32 := Net.Buffers.NET_ALLOC_SIZE * 256;

   procedure Initialize (Ifnet : in out Net.Interfaces.STM32.STM32_Ifnet;
                         Mac_Src : Ether_Addr);



   function Send_Message (Buffer : in out Net.Buffers.Buffer_Type;
                          Ifnet : in out Net.Interfaces.STM32.STM32_Ifnet;
                          Ether : in out Net.Headers.Ether_Header_Access;
                          Mac_Src : Ether_Addr; Mac_Dst : Ether_Addr;
                          Protocol : Uint16; Message :  Message_Type) return Boolean;


   function Get_Message (Ifnet : in out Net.Interfaces.STM32.STM32_Ifnet;
                         Packet : in out Net.Buffers.Buffer_Type) return Message_Type;

end STM32F7_Disco.Ethernet_Comunication;
