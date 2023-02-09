#!/bin/bash
echo "歡迎使用動畫瘋畫質、幀數提升器！"
echo "Written by JoshHuang | Power by Anime4K , RIFE ncnn Vulkan"
n=1
anime[n]=0
anime_ep[n]=0
time=0
dir=$(pwd)
duration=0
section=0
c=0
int=0
count=0
frames=0

for ((i=0;i<n;i++))
do 
read -p "[*] 請輸入第$[$i+1]個要放大、插幀的動漫名稱：" anime[$i]
read -p "[*] 請輸入${anime[$i]}的集數：" anime_ep[$i]
done

_get_fps()
{
echo "[*] 正在取得fps…"
frate=$(ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate $dir/"${anime[$time]}"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4)
g=${frate%/*}
h=${frate#*/}
fps_rate=$(echo "scale=4; $g.0/$h.0" | bc -l)
fps_float=$(echo "scale=4; $fps_rate*3.0" | bc -l)
fps_int=${fps_float%.*}fps
echo "[*] fps=$fps_rate"
echo "[*] 放大之後的fps=$fps_float"
}

_get_fps4K()
{
echo "[*] 正在取得fps…"
frate=$(ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate $dir/"${anime[$time]}4K"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K].mp4)
g=${frate%/*}
h=${frate#*/}
fps_rate=$(echo "scale=4; $g.0/$h.0" | bc -l)
fps_float=$(echo "scale=4; $fps_rate*3.0" | bc -l)
fps_int=${fps_float%.*}fps
echo "[*] fps=$fps_rate"
echo "[*] 放大之後的fps=$fps_float"
}

_get_section()
{
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $dir/"${anime[$time]}"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4)
int=${duration%.*}
section=$((int/30))
}

_check_anime()
{
if [[ -s "$dir/${anime[$time]}/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4" ]]
then 
echo "[*] 找到目標檔案！即將開始放大…"
if [[ -s "$dir/"${anime[$time]}4K"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K].mp4" ]]
then
echo "[*] 已經放大過了，跳過本集…"
_Rife4K
else
_Anime4K
fi
else 
echo "[-] 找不到指定檔案，請確認檔案名稱！或是檔案還沒下載下來！"
fi
}

_Anime4K()
{
if [[ ! -d ${anime[$time]}4K ]]
then
mkdir $dir/"${anime[$time]}4K"
fi
$dir/Anime4KCPP_CLI -q  -i $dir/"${anime[$time]}"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4 -o $dir/"${anime[$time]}4K"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K].mp4 -v
if [[ -s "$dir/"${anime[$time]}4K"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K].mp4" ]]
then
echo "[*] 放大成功！"
time=$((time+1))
if [ "$time" == "$n" ] 
then 
time=0
fi 
echo "[*] 下一集應該要放大的是【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4"
else
echo "[-] 放大完了但沒找到檔案…裂開…請debug後再試一次"
exit
fi
}

_Rife4K()
{
_get_fps4K
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $dir/"${anime[$time]}4K"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K].mp4)
int=${duration%.*}
section=$((int/30))
if [[ ! -d ${anime[$time]}4K_$fps_int ]]
then
echo "[*] 未找到資料夾，製作一個…"
mkdir $dir/"${anime[$time]}"4K_$fps_int
fi
echo "[*] 正在製作一個臨時資料夾…"
mkdir $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp
video_list=$dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/video_list.txt
echo "[*] 萃取音檔中…"
ffmpeg -i $dir/"${anime[$time]}4K"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K].mp4 -vn -acodec copy $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/audio.m4a
if [[ -s "$dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/audio.m4a" ]]
then
echo "[*] 萃取成功！"
else
echo "裂開…"
fi
echo "[*] 正在將影片分成$section段…"
ffmpeg -i $dir/"${anime[$time]}4K"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K].mp4  -c:v libx264 -sc_threshold 0 -g 30 -force_key_frames "expr:gte(t, n_forced * 30)" -segment_time 30 -f segment -segment_start_number 1 -individual_header_trailer 1 -reset_timestamps 1 $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/output%03d.mp4
for ((i=1;i<=$((section+1));i++))
do
c=$(printf "%03d" $i)
echo "[*] 正在製作輸入、輸出資料夾…"
mkdir $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/input_frames
mkdir $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/output_frames
echo "[*] 製作完成！準備萃取影片中的每一幀…"
ffmpeg -i $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/output$c.mp4 $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/input_frames/frame_%08d.png
frames=$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/output$c.mp4)
$dir/rife-ncnn-vulkan/rife-ncnn-vulkan -m $dir/rife-ncnn-vulkan/rife-v4.6 -n $((frames*3))  -i $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/input_frames -o $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/output_frames 
echo "[*] 正在將插幀完的圖片資料夾轉成片段…"
ffmpeg -framerate $fps_float -i $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/output_frames/%08d.png -c:a copy -crf 20 -c:v libx264 -pix_fmt yuv420p $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/Complete_output$c.mp4
if [[ -s "$dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/Complete_output$c.mp4" ]]
then 
echo "[*] 成功插幀！清理暫存資料夾中…"
rm -dr $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/input_frames
rm -dr $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/output_frames
rm $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/output$c.mp4
echo "[*] 紀錄檔案名稱中…"
echo "file '$dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/Complete_output$c.mp4'" >> "$video_list"
else 
echo "[-] 裂開…好像沒有成功插幀這個片段Complete_output$c.mp4"
exit
fi
done
_merge4K
if [[ -s "$dir/"${anime[$time]}"4K_$fps_int/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"]4K_$fps_int.mp4" ]]
then
echo "[*] 插幀完成！清除暫存資料夾中…"
rm -dr $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp
echo "[*] 正在移除原檔…"
rm $dir/"${anime[$time]}4K"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K].mp4
anime_ep[$time]=$(($anime_ep+1))
time=$((time+1)) 
if [ "$time" == "$n" ] 
then 
time=0
fi 
echo "[*] 下一集要插幀的是【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K].mp4"
else
echo "[*] 裂開…好像沒合併成功…"
exit
fi
}


_Rife_series()
{
if [[ -s "$dir/"${anime[$time]}"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4" ]]
then
echo "[*] 找到檔案！準備進行插幀…"
_Rife
else
echo "[*] 檔案不存在或還沒下載下來…"
fi
}
_Rife()
{
_get_fps
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $dir/"${anime[$time]}"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4)
int=${duration%.*}
section=$((int/30))
if [[ ! -d ${anime[$time]}720P_48fps ]]
then
echo "[*] 未找到資料夾，製作一個…"
mkdir $dir/"${anime[$time]}"720P_48fps
fi
echo "[*] 正在製作一個臨時資料夾…"
mkdir $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp
video_list=$dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/video_list.txt
echo "[*] 萃取音檔中…"
ffmpeg -i $dir/"${anime[$time]}"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4 -vn -acodec copy $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/audio.m4a
if [[ -s "$dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/audio.m4a" ]]
then
echo "[*] 萃取成功！"
else
echo "裂開…"
fi
echo "[*] 正在將影片分成$section段…"
ffmpeg -i $dir/"${anime[$time]}"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4  -c:v libx264 -sc_threshold 0 -g 30 -force_key_frames "expr:gte(t, n_forced * 30)" -segment_time 30 -f segment -segment_start_number 1 -individual_header_trailer 1 -reset_timestamps 1 $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/output%03d.mp4
for ((i=1;i<=$((section+1));i++))
do
c=$(printf "%03d" $i)
echo "[*] 正在製作輸入、輸出資料夾…"
mkdir $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/input_frames
mkdir $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/output_frames
echo "[*] 製作完成！準備萃取影片中的每一幀…"
ffmpeg -i $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/output$c.mp4 $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/input_frames/frame_%08d.png
frames=$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/output$c.mp4)
$dir/rife-ncnn-vulkan/rife-ncnn-vulkan -m '/home/josh/BaHaAnime4K/rife-ncnn-vulkan/rife-v4.6' -n $((frames*3))  -i $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/input_frames -o $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/output_frames 
echo "[*] 正在將插幀完的圖片資料夾轉成片段…"
ffmpeg -framerate $fps_float -i $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/output_frames/%08d.png -c:a copy -crf 20 -c:v libx264 -pix_fmt yuv420p $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/Complete_output$c.mp4
if [[ -s "$dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/Complete_output$c.mp4" ]]
then 
echo "[*] 成功插幀！清理暫存資料夾中…"
rm -dr $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/input_frames
rm -dr $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/output_frames
rm $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/output$c.mp4
echo "[*] 紀錄檔案名稱中…"
echo "file '$dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/Complete_output$c.mp4'" >> "$video_list"
else 
echo "[-] 裂開…好像沒有成功插幀這個片段Complete_output$c.mp4"
exit
fi
done
_merge
if [[ -s "$dir/"${anime[$time]}"720P_48fps/"${anime[$time]}"["${anime_ep[$time]}"]720P_48fps.mp4" ]]
then
echo "[*] 插幀完成！清除暫存資料夾中…"
rm -dr $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp
anime_ep[$time]=$(($anime_ep+1))
echo "[*] 下一集要插幀的是【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4"
else
echo "[*] 裂開…好像沒合併成功…"
exit
fi
}

_merge()
{
_get_section
for ((i=0;i<=$section;i++))
do
b=$((b+1))
c=$(printf "%03d" $b)
if [[ -s "$dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/Complete_output$c.mp4" ]]
then
count=$((count+1))
fi
done
if [ "$count"=="$section" ]
then
ffmpeg -f concat -safe 0 -i $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/video_list.txt -i $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P_48fps]_temp/audio.m4a -c:a copy -crf 20 -c:v libx264 -pix_fmt yuv420p $dir/"${anime[$time]}"720P_48fps/"${anime[$time]}"["${anime_ep[$time]}"]720P_48fps.mp4
fi
}

_merge4K()
{
ffmpeg -f concat -safe 0 -i $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/video_list.txt -i $dir/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][4K_$fps_int]_temp/audio.m4a -c:a copy -crf 20 -c:v libx264 -pix_fmt yuv420p $dir/"${anime[$time]}"4K_$fps_int/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"]4K_$fps_int.mp4
}

_test()
{
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $dir/"${anime[$time]}"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4)
int=${duration%.*}
section=$((int/600))
echo "$duration"
echo "$section"
}

while [ "1"=="1" ] 
do
_check_anime
sleep 60
done
