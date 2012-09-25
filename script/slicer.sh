SLICERVARS=$@

#echo $2
#sudo chown sliceruser:slicerusers $2 # was causing errors in ruby trying to unlink the config temp file
sudo chmod 644 $2

#echo "su sliceruser -c \"~/slic3r/slic3r.pl $SLICERVARS\""
su sliceruser -c "~/slic3r/slic3r.pl $SLICERVARS"

