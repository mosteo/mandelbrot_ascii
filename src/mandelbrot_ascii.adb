with Ada.Exceptions;
use Ada.Exceptions;
with Ada.Numerics.Elementary_Functions;
use Ada.Numerics.Elementary_Functions;
with Ada.Finalization;
with Ada.Calendar;
with Ada.Unchecked_Deallocation;
with Ada.Numerics.Generic_Complex_Types;
with Ada.Text_IO.Complex_IO;
with Ada.Text_IO;
use Ada.Text_IO;
with Ada.Streams;
use Ada.Streams;

--  Taken from https://ideone.com/a1ky4l
--  Author: David Given http://cowlark.com/

procedure Mandelbrot_Ascii is
  -- We want to use complex numbers, which are defined in the Ada standard
  -- library as a generic. (So you get to pick which precision you want.)
  package Complex_Types is new Ada.Numerics.Generic_Complex_Types(float);
  use Complex_Types;

  -- Configuration constants.
  bitmapsize: constant := 128; -- pixels
  maxiterations: constant := 32;
  threads: constant := 4;

  -- Returns the intensity of a single point in the Mandelbrot set.
  function RenderPixel(c: Complex) return float is
    z: Complex := Complex'(0.0, 0.0);
  begin
    for n in integer range 0..maxiterations loop
      z := z*z + c;
      if (abs z > 2.0) then
        return float(n) / float(maxiterations);
      end if;
    end loop;
    return 0.0;
  end;

  -- The bitmap (well, floatmap) which the rendered Mandelbrot is going to
  -- live in.
  type Bitmap is array(integer range <>, integer range <>) of float;
  type BitmapRef is access Bitmap;

  -- Encapsulates the multithreaded render: creates a bunch of workers
  -- and a scheduler, which hands out work units to the renderers.
  procedure Mandelbrot(data: BitmapRef;
                      r1, i1, r2, i2: float) is
    width: integer := data'length(1);
    height: integer := data'length(2);
    xdelta: float := (r2-r1) / float(width);
    ydelta: float := (i2-i1) / float(height);

    task Scheduler is
      -- Each worker calls this to find out what it needs to do.
      entry RequestWorkUnit(y: out integer; i: out float);
    end;

    task body Scheduler is
    begin
      -- Hand out each scanline in turn to tasks that want things to
      -- do, then exit.
      for yy in data'range(2) loop
        accept RequestWorkUnit(y: out integer; i: out float) do
          y := yy;
          i := i1 + float(yy)*ydelta;
        end RequestWorkUnit;
      end loop;
    end;

    -- Actually does the rendering. Each of these is self contained and will
    -- keep working until there's nothing left to do, at which point it
    -- exits.
    task type Worker;
    task body Worker is
      y: integer;
      i: float;
      c: Complex;
    begin
      -- Keep asking for stuff to do, then do it. When the Scheduler
      -- has terminated, requesting a work unit will throw an exception and
      -- the task will safely exit.
      loop
        Scheduler.RequestWorkUnit(y, i);

        for x in data'range(1) loop
          c := Complex'(r1 + float(x)*xdelta, i);
          data(x, y) := RenderPixel(c);
        end loop;
      end loop;
    end;

    -- Create some work threads (which will automatically start).
    scanlines: array(integer range 1..threads) of Worker;
  begin
    null; -- nothing to do in the main body, just wait for tasks to exit
  end;

  -- This sucks, but I couldn't find any other way to get ideone to emit
  -- Unicode procedurally. (The UTF-8 representation of each of these is
  -- three bytes. Coincidence? I think not.)
  glyphs: constant array(0..255) of string(1..3) :=
  ("⠀", "⠁", "⠂", "⠃", "⠄", "⠅", "⠆", "⠇", "⠈", "⠉", "⠊", "⠋", "⠌", "⠍",
   "⠎", "⠏", "⠐", "⠑", "⠒", "⠓", "⠔", "⠕", "⠖", "⠗", "⠘", "⠙", "⠚", "⠛",
   "⠜", "⠝", "⠞", "⠟", "⠠", "⠡", "⠢", "⠣", "⠤", "⠥", "⠦", "⠧", "⠨", "⠩",
   "⠪", "⠫", "⠬", "⠭", "⠮", "⠯", "⠰", "⠱", "⠲", "⠳", "⠴", "⠵", "⠶", "⠷",
   "⠸", "⠹", "⠺", "⠻", "⠼", "⠽", "⠾", "⠿", "⡀", "⡁", "⡂", "⡃", "⡄", "⡅",
   "⡆", "⡇", "⡈", "⡉", "⡊", "⡋", "⡌", "⡍", "⡎", "⡏", "⡐", "⡑", "⡒", "⡓",
   "⡔", "⡕", "⡖", "⡗", "⡘", "⡙", "⡚", "⡛", "⡜", "⡝", "⡞", "⡟", "⡠", "⡡",
   "⡢", "⡣", "⡤", "⡥", "⡦", "⡧", "⡨", "⡩", "⡪", "⡫", "⡬", "⡭", "⡮", "⡯",
   "⡰", "⡱", "⡲", "⡳", "⡴", "⡵", "⡶", "⡷", "⡸", "⡹", "⡺", "⡻", "⡼", "⡽",
   "⡾", "⡿", "⢀", "⢁", "⢂", "⢃", "⢄", "⢅", "⢆", "⢇", "⢈", "⢉", "⢊", "⢋",
   "⢌", "⢍", "⢎", "⢏", "⢐", "⢑", "⢒", "⢓", "⢔", "⢕", "⢖", "⢗", "⢘", "⢙",
   "⢚", "⢛", "⢜", "⢝", "⢞", "⢟", "⢠", "⢡", "⢢", "⢣", "⢤", "⢥", "⢦", "⢧",
   "⢨", "⢩", "⢪", "⢫", "⢬", "⢭", "⢮", "⢯", "⢰", "⢱", "⢲", "⢳", "⢴", "⢵",
   "⢶", "⢷", "⢸", "⢹", "⢺", "⢻", "⢼", "⢽", "⢾", "⢿", "⣀", "⣁", "⣂", "⣃",
   "⣄", "⣅", "⣆", "⣇", "⣈", "⣉", "⣊", "⣋", "⣌", "⣍", "⣎", "⣏", "⣐", "⣑",
   "⣒", "⣓", "⣔", "⣕", "⣖", "⣗", "⣘", "⣙", "⣚", "⣛", "⣜", "⣝", "⣞", "⣟",
   "⣠", "⣡", "⣢", "⣣", "⣤", "⣥", "⣦", "⣧", "⣨", "⣩", "⣪", "⣫", "⣬", "⣭",
   "⣮", "⣯", "⣰", "⣱", "⣲", "⣳", "⣴", "⣵", "⣶", "⣷", "⣸", "⣹", "⣺", "⣻",
   "⣼", "⣽", "⣾", "⣿");
  
  -- Writes the bitmap to stdout, using funky Unicode hackery to make it
  -- look pretty. Sort of.
  procedure DumpBitmap(data: BitmapRef) is
    function IsSet(x, y: integer) return boolean is
    begin
     	return data(x, y) > 0.0;
    end;

	type byte is mod 2**8;
    x, y: integer;
    b: byte;
  begin
    y := 0;
    while (y <= data'last(2)) loop
      x := 0;
      while (x < data'last(1)) loop
      	b := 0;
     	if IsSet(x+0, y+0) then b := b or 1; end if;
     	if IsSet(x+0, y+1) then b := b or 2; end if;
     	if IsSet(x+0, y+2) then b := b or 4; end if;
     	if IsSet(x+0, y+3) then b := b or 64; end if;
     	if IsSet(x+1, y+0) then b := b or 8; end if;
     	if IsSet(x+1, y+1) then b := b or 16; end if;
     	if IsSet(x+1, y+2) then b := b or 32; end if;
     	if IsSet(x+1, y+3) then b := b or 128; end if;
     	Put(glyphs(byte'pos(b)));
      	x := x + 2;
      end loop;
      Put_Line("");
      y := y + 4;
    end loop;
  end;
  
  image: BitmapRef;
  width: constant := bitmapsize;
  height: constant := width;
begin
  -- Render, print, then leak a bitmap.
  image := new Bitmap(0..(width-1), 0..(height-1));
  Mandelbrot(image, -2.0, -2.0, +2.0, +2.0);
  DumpBitmap(image);
exception
  when e: others =>
    Put_Line(Exception_Information(e));
end;
