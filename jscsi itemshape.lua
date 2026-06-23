desc:ItemShape
// MFM EDIT VERSION: 7.3 - PITCH FIRST PARAM = SLIDER 29
// Lock/RecordArm row 29..36 (Pitch first)
// Mute/Bypass row 38..45
// Pitch step: -12, -7, -5, -3, 0, +3, +5, +7, +12

// ---------- CONTROL SLIDERS (1..28) ----------
slider1:0<-12,12,0.1>Pitch Coarse
slider2:0<-12,12,0.01>Pitch Fine
slider3:4<0,8,1{-12,-7,-5,-3,0,+3,+5,+7,+12}>Pitch Step

slider4:1<0.1,4,0.1>Playrate Coarse
slider5:1<0.1,4,0.01>Playrate Fine
slider6:1<0.1,4,0.1>Playrate Step

slider7:0<-100,100,1>Pan Coarse %
slider8:0<-100,100,0.1>Pan Fine %
slider9:0<-100,100,10>Pan Step %

slider10:50<0,100,1>XFade Center Coarse %
slider11:50<0,100,0.1>XFade Center Fine %
slider12:0<0,6,1{Linear,SlowStart,SlowEnd,FastStart,FastEnd,Bevel,Sharp}>XFade Type
slider13:0<0,6,1{Linear,SlowStart,SlowEnd,FastStart,FastEnd,Bevel,Sharp}>XFade Type Fine

slider14:50<0,100,1>XFade Length Coarse %
slider15:50<0,100,0.1>XFade Length Fine %
slider16:0<0,6,1{Linear,SlowStart,SlowEnd,FastStart,FastEnd,Bevel,Sharp}>XFade Type Alt
slider17:0<0,6,1{Linear,SlowStart,SlowEnd,FastStart,FastEnd,Bevel,Sharp}>XFade Type Alt Fine
slider18:50<0,100,1>XFade Length Step %

slider19:0<0,100,1>Fade In Length Coarse %
slider20:0<0,100,0.1>Fade In Length Fine %
slider21:0<0,6,1{Linear,SlowStart,SlowEnd,FastStart,FastEnd,Bevel,Sharp}>Fade In Type
slider22:0<0,6,1{Linear,SlowStart,SlowEnd,FastStart,FastEnd,Bevel,Sharp}>Fade In Type Fine

slider23:0<0,100,1>Fade Out Length Coarse %
slider24:0<0,100,0.1>Fade Out Length Fine %
slider25:0<0,6,1{Linear,SlowStart,SlowEnd,FastStart,FastEnd,Bevel,Sharp}>Fade Out Type
slider26:0<0,6,1{Linear,SlowStart,SlowEnd,FastStart,FastEnd,Bevel,Sharp}>Fade Out Type Fine

slider27:0<-24,24,0.5>Item Volume Coarse dB
slider28:0<-24,24,0.1>Item Volume Fine dB

// ---------- LOCK ROW (29..36) — PITCH FIRST ----------
slider29:0<0,1,1{UNLOCK,LOCK}>Lock 1 Pitch
slider30:0<0,1,1{UNLOCK,LOCK}>Lock 2 Playrate
slider31:0<0,1,1{UNLOCK,LOCK}>Lock 3 Pan
slider32:0<0,1,1{UNLOCK,LOCK}>Lock 4 XFadeCenter
slider33:0<0,1,1{UNLOCK,LOCK}>Lock 5 XFadeLength
slider34:0<0,1,1{UNLOCK,LOCK}>Lock 6 FadeIn
slider35:0<0,1,1{UNLOCK,LOCK}>Lock 7 FadeOut
slider36:0<0,1,1{UNLOCK,LOCK}>Lock 8 Volume

// ---------- VOLUME STEP (37) ----------
slider37:0<-24,24,6>Item Volume Step dB

// ---------- MUTE / BYPASS ROW (38..45) ----------
slider38:0<0,1,1{ON,BYPASS}>Bypass 1 Pitch
slider39:0<0,1,1{ON,BYPASS}>Bypass 2 Playrate
slider40:0<0,1,1{ON,BYPASS}>Bypass 3 Pan
slider41:0<0,1,1{ON,BYPASS}>Bypass 4 XFadeCenter
slider42:0<0,1,1{ON,BYPASS}>Bypass 5 XFadeLength
slider43:0<0,1,1{ON,BYPASS}>Bypass 6 FadeIn
slider44:0<0,1,1{ON,BYPASS}>Bypass 7 FadeOut
slider45:0<0,1,1{ON,BYPASS}>Bypass 8 Volume

in_pin:none
out_pin:none

@init
function pitch_step_value(idx)
(
  idx == 0 ? -12 :
  idx == 1 ?  -7 :
  idx == 2 ?  -5 :
  idx == 3 ?  -3 :
  idx == 4 ?   0 :
  idx == 5 ?   3 :
  idx == 6 ?   5 :
  idx == 7 ?   7 :
                12;
);

function pitch_step_snap(v) local(best, bestd, d, i, cand)
(
  best = 0; bestd = 1e9; i = 0;
  loop(9,
    cand = pitch_step_value(i);
    d = abs(v - cand);
    d < bestd ? ( bestd = d; best = cand; );
    i += 1;
  );
  best;
);

function clamp_shape(v) ( v < 0 ? 0 : v > 6 ? 6 : v; );
function clamp_lock(v)  ( v >= 0.5 ? 1 : 0; );
function clamp_byp(v)   ( v >= 0.5 ? 1 : 0; );

pitch_coarse = 0; pitch_fine = 0; pitch_step = 0;
playrate_coarse = 1; playrate_fine = 1; playrate_step = 1;
pan_coarse = 0; pan_fine = 0; pan_step = 0;
xfade_center_coarse = 50; xfade_center_fine = 50;
xfade_type = 0; xfade_type_fine = 0;
xfade_length_coarse = 50; xfade_length_fine = 50;
xfade_type_alt = 0; xfade_type_alt_fine = 0; xfade_length_step = 50;
fadein_length_coarse = 0; fadein_length_fine = 0;
fadein_type = 0; fadein_type_fine = 0;
fadeout_length_coarse = 0; fadeout_length_fine = 0;
fadeout_type = 0; fadeout_type_fine = 0;
volume_coarse = 0; volume_fine = 0; volume_step = 0;

lock_pitch = 0; lock_playrate = 0; lock_pan = 0;
lock_xfade_center = 0; lock_xfade_length = 0;
lock_fadein = 0; lock_fadeout = 0; lock_volume = 0;

byp_pitch = 0; byp_playrate = 0; byp_pan = 0;
byp_xfade_center = 0; byp_xfade_length = 0;
byp_fadein = 0; byp_fadeout = 0; byp_volume = 0;

eng_pitch = 0;
eng_playrate = 1;
eng_pan = 0;
eng_xfade_center = 50;
eng_xfade_length = 50;
eng_fadein_length = 0;
eng_fadeout_length = 0;
eng_volume = 0;
eng_xfade_type = 0;
eng_xfade_type_alt = 0;
eng_fadein_type = 0;
eng_fadeout_type = 0;

@slider
pitch_coarse        = slider1;
pitch_fine          = slider2;
pitch_step          = pitch_step_snap( pitch_step_value(slider3) );

playrate_coarse     = slider4;
playrate_fine       = slider5;
playrate_step       = slider6;

pan_coarse          = slider7;
pan_fine            = slider8;
pan_step            = slider9;

xfade_center_coarse = slider10;
xfade_center_fine   = slider11;
xfade_type          = clamp_shape(slider12);
xfade_type_fine     = clamp_shape(slider13);

xfade_length_coarse = slider14;
xfade_length_fine   = slider15;
xfade_type_alt      = clamp_shape(slider16);
xfade_type_alt_fine = clamp_shape(slider17);
xfade_length_step   = slider18;

fadein_length_coarse = slider19;
fadein_length_fine   = slider20;
fadein_type          = clamp_shape(slider21);
fadein_type_fine     = clamp_shape(slider22);

fadeout_length_coarse = slider23;
fadeout_length_fine   = slider24;
fadeout_type          = clamp_shape(slider25);
fadeout_type_fine     = clamp_shape(slider26);

volume_coarse = slider27;
volume_fine   = slider28;

lock_pitch        = clamp_lock(slider29);
lock_playrate     = clamp_lock(slider30);
lock_pan          = clamp_lock(slider31);
lock_xfade_center = clamp_lock(slider32);
lock_xfade_length = clamp_lock(slider33);
lock_fadein       = clamp_lock(slider34);
lock_fadeout      = clamp_lock(slider35);
lock_volume       = clamp_lock(slider36);

volume_step = slider37;

byp_pitch        = clamp_byp(slider38);
byp_playrate     = clamp_byp(slider39);
byp_pan          = clamp_byp(slider40);
byp_xfade_center = clamp_byp(slider41);
byp_xfade_length = clamp_byp(slider42);
byp_fadein       = clamp_byp(slider43);
byp_fadeout      = clamp_byp(slider44);
byp_volume       = clamp_byp(slider45);

// LOCK freezes engine value; BYPASS forces neutral; else apply live value
eng_pitch =
  lock_pitch ? eng_pitch :
  byp_pitch  ? 0 :
               (pitch_coarse + pitch_fine + pitch_step);

eng_playrate =
  lock_playrate ? eng_playrate :
  byp_playrate  ? 1 :
                  (playrate_coarse * playrate_fine * playrate_step);

eng_pan =
  lock_pan ? eng_pan :
  byp_pan  ? 0 :
             (pan_coarse + pan_fine + pan_step);

eng_xfade_center =
  lock_xfade_center ? eng_xfade_center :
  byp_xfade_center  ? 50 :
                      ((xfade_center_coarse + xfade_center_fine) * 0.5);

eng_xfade_length =
  lock_xfade_length ? eng_xfade_length :
  byp_xfade_length  ? 0 :
                      ((xfade_length_coarse + xfade_length_fine + xfade_length_step) / 3);

eng_fadein_length =
  lock_fadein ? eng_fadein_length :
  byp_fadein  ? 0 :
                ((fadein_length_coarse + fadein_length_fine) * 0.5);

eng_fadeout_length =
  lock_fadeout ? eng_fadeout_length :
  byp_fadeout  ? 0 :
                 ((fadeout_length_coarse + fadeout_length_fine) * 0.5);

eng_volume =
  lock_volume ? eng_volume :
  byp_volume  ? 0 :
                (volume_coarse + volume_fine + volume_step);

eng_xfade_type =
  lock_xfade_center ? eng_xfade_type :
  byp_xfade_center  ? 0 :
                      xfade_type;

eng_xfade_type_alt =
  lock_xfade_length ? eng_xfade_type_alt :
  byp_xfade_length  ? 0 :
                      xfade_type_alt;

eng_fadein_type =
  lock_fadein ? eng_fadein_type :
  byp_fadein  ? 0 :
                fadein_type;

eng_fadeout_type =
  lock_fadeout ? eng_fadeout_type :
  byp_fadeout  ? 0 :
                 fadeout_type;

// Echo cleaned values back
slider12 = xfade_type;     slider13 = xfade_type_fine;
slider16 = xfade_type_alt; slider17 = xfade_type_alt_fine;
slider21 = fadein_type;    slider22 = fadein_type_fine;
slider25 = fadeout_type;   slider26 = fadeout_type_fine;

slider29 = lock_pitch;        slider30 = lock_playrate;
slider31 = lock_pan;          slider32 = lock_xfade_center;
slider33 = lock_xfade_length; slider34 = lock_fadein;
slider35 = lock_fadeout;      slider36 = lock_volume;

slider38 = byp_pitch;         slider39 = byp_playrate;
slider40 = byp_pan;           slider41 = byp_xfade_center;
slider42 = byp_xfade_length;  slider43 = byp_fadein;
slider44 = byp_fadeout;       slider45 = byp_volume;

sliderchange(slider3);
sliderchange(slider12); sliderchange(slider13);
sliderchange(slider16); sliderchange(slider17);
sliderchange(slider21); sliderchange(slider22);
sliderchange(slider25); sliderchange(slider26);
sliderchange(slider29); sliderchange(slider30);
sliderchange(slider31); sliderchange(slider32);
sliderchange(slider33); sliderchange(slider34);
sliderchange(slider35); sliderchange(slider36);
sliderchange(slider37);
sliderchange(slider38); sliderchange(slider39);
sliderchange(slider40); sliderchange(slider41);
sliderchange(slider42); sliderchange(slider43);
sliderchange(slider44); sliderchange(slider45);

@block
// no audio processing — control surface only

@gfx 640 260
gfx_setfont(1, "Arial", 14);
gfx_set(0.08, 0.08, 0.10, 1);
gfx_rect(0, 0, gfx_w, gfx_h);

cell_w  = gfx_w / 8;
y_label = 8;
y_value = 30;
y_lock  = 58;
y_byp   = 80;
y_lower = 104;

i = 0;
loop(8,
  x = i * cell_w + 6;

  gfx_set(0.65, 0.65, 0.70, 1);
  gfx_x = x; gfx_y = y_label;
  i == 0 ? gfx_drawstr("CH1  PITCH") :
  i == 1 ? gfx_drawstr("CH2  RATE")  :
  i == 2 ? gfx_drawstr("CH3  PAN")   :
  i == 3 ? gfx_drawstr("CH4  XfCTR") :
  i == 4 ? gfx_drawstr("CH5  XfLEN") :
  i == 5 ? gfx_drawstr("CH6  FaIN")  :
  i == 6 ? gfx_drawstr("CH7  FaOUT") :
           gfx_drawstr("CH8  VOL");

  gfx_set(1, 1, 1, 1);
  gfx_x = x; gfx_y = y_value;
  i == 0 ? gfx_printf("%+.2f st", eng_pitch) :
  i == 1 ? gfx_printf("%.2fx",    eng_playrate) :
  i == 2 ? gfx_printf("%+.0f%%",  eng_pan) :
  i == 3 ? gfx_printf("%.0f%%",   eng_xfade_center) :
  i == 4 ? gfx_printf("%.0f%%",   eng_xfade_length) :
  i == 5 ? gfx_printf("%.0f%%",   eng_fadein_length) :
  i == 6 ? gfx_printf("%.0f%%",   eng_fadeout_length) :
           gfx_printf("%+.1f dB",  eng_vol