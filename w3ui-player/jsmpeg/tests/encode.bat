@echo off
set ffmpeg=.\ffmpeg\bin\ffmpeg.exe

:: MPEG1 is a low bit rate format, designed to be used on CD running at a rate of less than 1.5Mb/s. Comparative to MPEG2, MPEG1 will generally out perform MPEG2 at lower bit rates, though MPEG4 should out perform MPEG1.
:: There is no audio encoder for MPEG 1 audio, although there is a decoder. For audio simply use MPEG 2 (mp2) audio as this will work with most high end encoders.

:: For a single pass mpeg1
::%ffmpeg% -i "test" -vcodec mpeg1video -acodec mp2 "output_file.mpeg"
::%ffmpeg% -i "test.mp4" -c:v theora -c:a libvorbis -y "temp.ogv"
%ffmpeg% -i "test.mp4" -c:v mpeg1video -c:a mp2 -y -f matroska  "test.mkv"

:: For a two pass mpeg1 encoding
::ffmpeg -i "input_video" -pass 1 -f mpeg1video -an -passlogfile log_file "output_file.mpeg"
::ffmpeg -i "input_video" -pass 2 -f mpeg1video -acodec mp2 -passlogfile log_file "output_file.mpeg"

:: For an optimized two pass mpeg1 encoding
::ffmpeg -i "input_video" -pass 1 -f mpeg1video -b 750000 -s 320x240 -an -passlogfile log_file "output_file.mpeg"
::ffmpeg -i "input_video" -pass 2 -f mpeg1video -b 750000 -s 320x240 -acodec mp2 -ab 128000 -passlogfile log_file "output_file.mpeg"

exit
