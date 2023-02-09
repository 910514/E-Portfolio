#!/bin/bash
echo "歡迎使用動畫瘋畫質、幀數提升器！"
echo "Written by JoshHuang | Power by Anime4K , RIFE ncnn Vulkan"
n=0
anime[n]=0
time=0
dir=$(pwd)
duration=0
section=0
c=0
int=0
count=0
frames=0

read -p "[*] 請輸入有幾部動漫要放大、插幀:" n
for ((i=0;i<n;i++))
do 
read -p "[*] 請輸入第$[$i+1]個要放大、插幀的動漫名稱：" anime[$i]
done

_new_get_fps_4k()
{
echo "[*] 正在取得fps…"
frate=$(ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate $dir/"${anime[$time]}4K"/"${folder_contents[$i]}")
g=${frate%/*}
h=${frate#*/}
fps_rate=$(echo "scale=4; $g.0/$h.0" | bc -l)
fps_float=$(echo "scale=4; $fps_rate*3.0" | bc -l)
fps_int=${fps_float%.*}fps
echo "[*] fps=$fps_rate"
echo "[*] 放大之後的fps=$fps_float"
echo "[*] 取整數的fps = $fps_int"
}

_get_section()
{
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $dir/"${anime[$time]}"/【動畫瘋】"${anime[$time]}"["${anime_ep[$time]}"][720P].mp4)
int=${duration%.*}
section=$((int/30))
}

_check_anime()
{
cd "$dir"/"${anime[$time]}"
folder_contents=( $(ls) )
file_number=$(ls | wc -l)
if [ $file_number -ne 0 ]
then 
echo "[*] 資料夾內還有動漫...即將開始放大..."
_Anime4K
else
echo "[-] 已全數完成放大，等待新的檔案..."
fi
}

_check_anime4K()
{
cd "$dir"/"${anime[$time]}4K"
folder_contents=( $(ls) )
file_number=$(ls | wc -l)
if [ $file_number -ne 0 ]
then 
echo "[*] 資料夾內還有動漫...即將開始放大..."
_RifeRW
else
echo "[-] 已全數完成放大，等待新的檔案..."
fi
}

_Anime4K()
{
cd "$dir"/"${anime[$time]}"
folder_contents=( $(ls) )
file_number=$(ls | wc -l)
if [[ ! -d ${anime[$time]}4K ]]
then
mkdir $dir/"${anime[$time]}4K"
fi
pfolder_contents=( "${folder_contents[@]/"720P"/"4K"}" )
for ((i=0;i<$file_number;i++))
do
$dir/Anime4KCPP_CLI -q  -i "${folder_contents[$i]}"  -o $dir/"${anime[$time]}4K"/"${pfolder_contents[$i]}" -v
if [[ -s "$dir/"${anime[$time]}4K"/"${pfolder_contents[$i]}"" ]]
then
echo "[*] 放大成功！"
curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"[*] 放大成功！,"${pfolder_contents[$i]}"\"}" https://discord.com/api/webhooks/1070143068138917978/OgypSJgYaZglzc2bOdtWMAN09mfVsKhslg83-VFs2kyN-hu_o9Y50rS3e1PbM5Ie6oT3
echo "[*] 移除遠檔中..."
rm "${folder_contents[$i]}"
if [ $((file_number-1)) -ne 0 ]
then
echo "[*] 下一個放大的是"${folder_contents[$((i+1))]}""
curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"[*] 下一個放大的是"${folder_contents[$((i+1))]}"\"}" https://discord.com/api/webhooks/1070143068138917978/OgypSJgYaZglzc2bOdtWMAN09mfVsKhslg83-VFs2kyN-hu_o9Y50rS3e1PbM5Ie6oT3
fi
else
echo "[-] 放大完了但沒找到檔案…裂開…請debug後再試一次"
exit
fi
done
}

_RifeRW()
{
cd "$dir"/"${anime[$time]}4K"
folder_contents=( $(ls) )
file_number=$(ls | wc -l)
wfolder_contents=()
for item in "${folder_contents[@]}"; do
  filename="${item%.*}"
  wfolder_contents+=("$filename")
done
for ((i=0;i<$file_number;i++))
do
_new_get_fps_4k
if [[ ! -d ${anime[$time]}4K_$fps_int ]]
then
echo "[*] 未找到資料夾，製作一個…"
mkdir $dir/"${anime[$time]}"4K_$fps_int
fi
if [[ ! -d $dir/temp ]]
then
echo "[*] 未找到暫存資料夾，製作一個…"
mkdir $dir/temp
fi
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $dir/"${anime[$time]}4K"/"${folder_contents[$i]}")
int=${duration%.*}
section=$((int/30))
echo "[*] 正在製作一個臨時資料夾…"
mkdir $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp
video_list=$dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/video_list.txt
echo "[*] 萃取音檔中…"
ffmpeg -i $dir/"${anime[$time]}4K"/"${folder_contents[$i]}" -vn -acodec copy $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/audio.m4a
if [[ -s "$dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/audio.m4a" ]]
then
echo "[*] 萃取成功！"
else
echo "裂開…"
fi
echo "[*] 正在將影片分成$section段…"
ffmpeg -i $dir/"${anime[$time]}4K"/"${folder_contents[$i]}"  -c:v libx264 -sc_threshold 0 -g 30 -force_key_frames "expr:gte(t, n_forced * 30)" -segment_time 30 -f segment -segment_start_number 1 -individual_header_trailer 1 -reset_timestamps 1 $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/output%03d.mp4
for ((j=0;j<$section;j++))
do
c=$(printf "%03d" $((j+1)))
echo "[*] 正在製作輸入、輸出資料夾…"
mkdir $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/input_frames
mkdir $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/output_frames
echo "[*] 製作完成！準備萃取影片中的每一幀…"
ffmpeg -i $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/output$c.mp4 $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/input_frames/frame_%08d.png
frames=$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/output$c.mp4)
$dir/rife-ncnn-vulkan/rife-ncnn-vulkan -m $dir/rife-ncnn-vulkan/rife-v4.6 -n $((frames*3))  -i $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/input_frames -o $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/output_frames 
echo "[*] 正在將插幀完的圖片資料夾轉成片段…"
ffmpeg -framerate $fps_float -i $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/output_frames/%08d.png -c:a copy -crf 20 -c:v libx264 -pix_fmt yuv420p $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/Complete_output$c.mp4
if [[ -s "$dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/Complete_output$c.mp4" ]]
then 
echo "[*] 成功插幀！清理暫存資料夾中…"
rm -dr $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/input_frames
rm -dr $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/output_frames
rm $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/output$c.mp4
echo "[*] 紀錄檔案名稱中…"
echo "file '$dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/Complete_output$c.mp4'" >> "$video_list"
else 
echo "[-] 裂開…好像沒有成功插幀這個片段Complete_output$c.mp4"
exit
fi
done
_merge4KRW
if [[ -s "$dir/"${anime[$time]}"4K_$fps_int/"${wfolder_contents[$i]}"[$fps_int].mp4" ]]
then
echo "[*] 插幀完成！清除暫存資料夾中…"
rm -dr $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp
echo "[*] 正在移除原檔…"
rm $dir/"${anime[$time]}4K"/"${folder_contents[$i]}" 
curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"[*] 完成插幀！"${folder_contents[$i]}"\"}" https://discord.com/api/webhooks/1070143068138917978/OgypSJgYaZglzc2bOdtWMAN09mfVsKhslg83-VFs2kyN-hu_o9Y50rS3e1PbM5Ie6oT3
if [ $((file_number-1)) -ne 0 ]
then
echo "[*] 下一集要插幀的是$dir/"${anime[$time]}4K"/"${folder_contents[$((i+1))]}""
curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"[*] 下一集要插幀的是"${folder_contents[$((i+1))]}"\"}" https://discord.com/api/webhooks/1070143068138917978/OgypSJgYaZglzc2bOdtWMAN09mfVsKhslg83-VFs2kyN-hu_o9Y50rS3e1PbM5Ie6oT3
fi
else
echo "[-] 裂開…好像沒合併成功…"
curl -i -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data "{\"content\": \"[-] 裂開…好像沒合併成功…,插幀"${wfolder_contents[$i]}"[$fps_int].mp4時出現錯誤\"}" https://discord.com/api/webhooks/1070143068138917978/OgypSJgYaZglzc2bOdtWMAN09mfVsKhslg83-VFs2kyN-hu_o9Y50rS3e1PbM5Ie6oT3
exit
fi
done
}

_merge4KRW()
{
ffmpeg -f concat -safe 0 -i $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/video_list.txt -i $dir/temp/"${wfolder_contents[$i]}"[$fps_int]_temp/audio.m4a -c:a copy -crf 20 -c:v libx264 -pix_fmt yuv420p $dir/"${anime[$time]}"4K_$fps_int/"${wfolder_contents[$i]}"[$fps_int].mp4
}

while [ "1" == "1" ] 
do
time=$((time+1)) 
if [ "$time" == "$n" ] 
then 
time=0
fi
_check_anime
_check_anime4K
sleep 60
done
