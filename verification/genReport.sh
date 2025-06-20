echo "no.10, vcs design status\n"

make check_compile
mv ./vcs_design_stats.log ../doc/10-vcsDesignStats/

echo "no.11, vcs simprofile\n"
# time usage
rm -rf ./profileReport
rm -rf ./simprofile_dir
rm profileReport.*
rm -rf ../doc/11-vcsSimprofile/time
mkdir ../doc/11-vcsSimprofile/time
make simp

./simv  -simprofile time


mv ./profileReport ../doc/11-vcsSimprofile/time/
mv ./simprofile_dir ../doc/11-vcsSimprofile/time/
mv profileReport.* ../doc/11-vcsSimprofile/time/


#mem usage
rm -rf ./profileReport
rm -rf ./simprofile_dir
rm profileReport.*
rm -rf ../doc/11-vcsSimprofile/mem
mkdir ../doc/11-vcsSimprofile/mem
make simp

./simv  -simprofile mem


mv ./profileReport ../doc/11-vcsSimprofile/mem/
mv ./simprofile_dir ../doc/11-vcsSimprofile/mem/
mv profileReport.* ../doc/11-vcsSimprofile/mem/