with STM32F7_Disco.Digital_IO;

with STM32.Board;
with HAL.Bitmap;
with BMP_Fonts;
with LCD_Std_Out;
with HAL;          use HAL; -- adc library
with STM32.Board;
with HAL.Bitmap;
with STM32.DMA2D;

with Ada.Real_Time; use Ada.Real_Time;

with Interfaces.C; use Interfaces.C;


with STM32.ADC; use STM32.ADC; -- ADC
with STM32.Device; use STM32.Device;  -- Analog_To_Digital_Converter
with STM32.GPIO; use STM32.GPIO;
with STM32.Board;  use STM32.Board;

procedure Automous_Car is
   Count : Integer := 100;
   BG : constant HAL.Bitmap.Bitmap_Color := (Alpha => 255, others => 64);

   --     Time_1 : Ada.Real_Time.Time;
   Period_TS : Ada.Real_Time.Time_Span := Milliseconds (20);
   --     Period_Duration : Duration;
   --     Salida : Boolean;



   --     Converter     : Analog_To_Digital_Converter renames ADC_1; -- adc instruction
   --     Input_Channel : constant Analog_Input_Channel := 1; -- adc instruction, channel 1
   --     Input1         : constant GPIO_Point := PA6; -- adc instruction, PA6 port
   --
   --     All_Regular_Conversions : constant Regular_Channel_Conversions :=
   --       (1 => (Channel => Input_Channel, Sample_Time => Sample_144_Cycles)); -- adc instruction
   --
   --     ADC_Sensor : constant ADC_Point :=  (STM32.Device.ADC_1'Access, Channel => Input_Channel);
   --
   --     Raw : UInt32 := 0; --adc instruction
   --
   --     Successful : Boolean; --adc instruction
   --
   --     procedure Configure_Analog_Input is --adc instruction
   --     begin -- adc
   --        Enable_Clock (Input1); --adc instruction
   --        Configure_IO (Input1, (Mode => Mode_Analog, Resistors => Floating)); -- adc instruction
   --     end Configure_Analog_Input; --adc instruction

begin

   Initialize_LEDs; -- adc instruction
   All_LEDs_On;
   delay until Ada.Real_Time.Clock +  To_Time_Span (1.0);
   All_LEDs_Off;

   --  inicializamos la pantalla
   STM32.Board.Display.Initialize;
   STM32.Board.Display.Initialize_Layer (1, HAL.Bitmap.ARGB_8888);
   LCD_Std_Out.Set_Font (BMP_Fonts.Font16x24);
   LCD_Std_Out.Current_Background_Color := BG;

   --  Motors on the right
   STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D11,
                                           Mode => STM32F7_Disco.Digital_IO.Output);
   STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D9,
                                           Mode => STM32F7_Disco.Digital_IO.Output);

   --  Motors on the left
   STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D7,
                                           Mode => STM32F7_Disco.Digital_IO.Output);
   STM32F7_Disco.Digital_IO.Configure_Pin (Pin  => STM32F7_Disco.Digital_IO.Pin_D8,
                                           Mode => STM32F7_Disco.Digital_IO.Output);

      --  velocidad ruedas derecha
      STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => STM32F7_Disco.Digital_IO.Pin_D6 ,
                                             Mode => STM32f7_Disco.Digital_IO.Output );
      STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D6,
                                             Value => True);
      --  velocidad ruedas izquierda
      STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => STM32f7_Disco.Digital_IO.Pin_D5 ,
                                             Mode => STM32f7_Disco.Digital_IO.Output );
      STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D5,
                                             Value => True);
   --
   --     --  sensor ultrasonido
   --     --  echo
   --     STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => STM32f7_Disco.Digital_IO.Pin_A4 ,
   --                                            Mode => STM32f7_Disco.Digital_IO.Input );
   --     --  Triggerping
   --     STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => STM32f7_Disco.Digital_IO.Pin_A5 ,
   --                                            Mode => STM32f7_Disco.Digital_IO.Output);
   --
   --     --  Servomotor
   --
   --     STM32f7_Disco.Digital_IO.Configure_Pin(Pin  => STM32f7_Disco.Digital_IO.Pin_D3 ,
   --                                            Mode => STM32f7_Disco.Digital_IO.Output );
   --     Time_0 := Clock;



   --    ADC  -----------------------------
   --
   --     Configure_Analog_Input; --adc instruction
   --
   --     Enable_Clock (Converter); --adc instruction
   --
   --     Reset_All_ADC_Units; --adc instruction
   --
   --     Configure_Common_Properties --adc instruction
   --       (Mode           => Independent, --adc instruction
   --        Prescalar      => PCLK2_Div_2, --adc instruction
   --        DMA_Mode       => Disabled, --adc instruction
   --        Sampling_Delay => Sampling_Delay_5_Cycles); --adc instruction
   --
   --     Configure_Unit --adc instruction
   --       (Converter, --adc instruction
   --        Resolution => ADC_Resolution_12_Bits, --adc instruction
   --        Alignment  => Right_Aligned); --adc instruction
   --
   --     Configure_Regular_Conversions --adc instruction
   --       (Converter, --adc instruction
   --        Continuous  => False, --adc instruction
   --        Trigger     => Software_Triggered, --adc instruction
   --        Enable_EOC  => True, --adc instruction
   --        Conversions => All_Regular_Conversions); --adc instruction
   --
   --     Enable (Converter); --adc instruction

   --    ADC  -----------------------------


   loop
      -------------------------------------------------------
      --    Inicio ADC
      -------------------------------------------------------
      --
      --        Start_Conversion (Converter); --adc instruction
      --
      --        Poll_For_Status (Converter, Regular_Channel_Conversion_Complete, Successful); --adc instruction
      --        Raw := UInt32 (Conversion_Value (Converter)); -- reading PA1
      --
      --        LCD_Std_Out.Clear_Screen;
      --        LCD_Std_Out.Put_Line ( "VALOR ADC: ");
      --        LCD_Std_Out.Put_Line ( RAW'Image);
      --
      --        delay until Clock + Milliseconds (100);

      -------------------------------------------------------
      --   FIN ADC
      -------------------------------------------------------
      -------------------------------------------------------
      --    Inicio de la parte del sensor de infrarojos
      -------------------------------------------------------
      --  0 GRADOS
      --                    for I  in 1 .. 50 loop
      --                       STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3,
      --                                                                Value => True);
      --                       delay 0.000_710;  --  1 ms
      --                       STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3,
      --                                                                Value => False);
      --                       delay 0.001_929;  --  18 ms
      --                    end loop;
      --                    delay 2.0;

      --
      --                    --  90 GRADOS
      --                    for I  in 1 .. 50 loop
      --                       STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3,
      --                                                                Value => True);
      --                       delay 0.001_000;  --  500 micros
      --                       STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3,
      --                                                                Value => False);
      --                       delay 0.019_000;  --  18 ms
      --                    end loop;
      --                    delay 2.0;
      --
      --
      --                   --  90 GRADOS
      --                    for I  in 1 .. 50 loop
      --                       STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3, Value => True);
      --                       delay 0.002;  --  2 ms
      --                       STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3, Value => False);
      --                       delay 0.018;  -- 18 ms
      --                     end loop;
      --
      --                    delay 2.0;



      --  -45 GRADOS
      --        for I  in 1 .. 50 loop
      --           STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3, Value => True);
      --           delay 0.000_500;  --  2 ms
      --           STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3, Value => False);
      --           delay 0.019_500;  -- 18 ms
      --        end loop;
      --
      --        delay 2.0;
      --
      --
      --        --  +45 GRADOS
      --        for I  in 1 .. 50 loop
      --           STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3, Value => True);
      --           delay 0.001_500;  --  2 ms
      --           STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3, Value => False);
      --           delay 0.018_500;  -- 18 ms
      --        end loop;
      --        delay 2.0;


      -------------------------------------------------------
      --    Inicio del segundo intento del SERVO
      -------------------------------------------------------
      --        delay until Time_0;
      --
      --        STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3, Value => True);
      --
      --        delay  until Time_0 + Microseconds (2000);
      --
      --        STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_D3, Value => False);
      --
      --
      --        Time_0 := Time_0 + Period_TS;

      -------------------------------------------------------
      --    FIN del segundo intento del SERVO
      -------------------------------------------------------



      -------------------------------------------------------
      --    Fin de la parte del sensor de infrarojos
      -------------------------------------------------------


      -------------------------------------------------------
      --    Inicio de la parte del sensor de infrarojos
      -------------------------------------------------------
      --
      --        STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_A5,
      --                                               Value => False);
      --        delay 0.000004;
      --
      --        STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_A5,
      --                                               Value => True);
      --        delay 0.000010;
      --
      --        STM32f7_Disco.Digital_IO.Digital_Write(Pin   => STM32f7_Disco.Digital_IO.Pin_A5,
      --                                               Value => False);
      --        delay 0.000004;
      --
      --        Time_0 := Ada.Real_Time.Clock;
      --
      --
      --        --        loop
      --        --           if (STM32f7_Disco.Digital_IO.Digital_Read(Pin => STM32f7_Disco.Digital_IO.Pin_A4)) then
      --        --
      --        --                    LCD_Std_Out.Put(X => 200, Y => 140, Msg =>"Pin_A4 True" );
      --        --
      --        --              Time_1 := Ada.Real_Time.Clock;
      --        --              Salida := True;
      --        --              delay 5.0;
      --        --           end if;
      --        --           exit when  Salida = True ;
      --        --        end loop;
      --        -------------------------------------------
      --        delay 0.000_005; -- 5 microsegundos
      --        Time_1 := Ada.Real_Time.Clock;
      --        Period_TS := Time_1 - Time_0;
      --        Period_Duration := Ada.Real_Time.To_Duration(TS => Period_TS);
      --        LCD_Std_Out.Put(X => 200, Y => 200, Msg =>Period_Duration'Img );
      --
      --
      --
      --
      --
      -------------------------------------------------------
      --    Fin de la parte del sensor de infrarojos
      -------------------------------------------------------



      ------------------------------------------
      --
      --        --        Aux := Period_TS * 10; --  microseconds
      --        --        Aux := Aux / 292;
      --        --        Aux := Aux / 2;
      --        --
      --        --        Period_Duration := Ada.Real_Time.To_Duration(TS => Aux);
      --        --
      --        --        LCD_Std_Out.Put(X => 200, Y => 240, Msg =>Period_Duration'Img );






      --  adelate
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                              Value => True);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                              Value => False);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                              Value => True);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                              Value => False);
      LCD_Std_Out.Put (X   => 1, Y   => 1,    Msg => "Adelante");
      delay until Ada.Real_Time.Clock +  Milliseconds (5000);
    -- atras

      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D11,
                                              Value => False);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D9,
                                              Value => True);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D7,
                                              Value => False);
      STM32F7_Disco.Digital_IO.Digital_Write (Pin   => STM32F7_Disco.Digital_IO.Pin_D8,
                                              Value => True);
      LCD_Std_Out.Put (X   => 1, Y   => 1,    Msg => "atras     ");
       delay until Ada.Real_Time.Clock +  To_Time_Span (10.0);



   end loop;


end Automous_Car;
