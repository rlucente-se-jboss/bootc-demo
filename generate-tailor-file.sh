#!/usr/bin/env bash

#
# get all of the high severity rules
#
HIGH_RULES_ONLY=high-rules-only.txt
xmlstarlet sel -N "xccdf-1.2=http://checklists.nist.gov/xccdf/1.2" \
  -t -v \
  "//xccdf-1.2:Rule[@severity='high']/@id" \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml | sort -u > $HIGH_RULES_ONLY

#
# get all of the selected DISA STIG rules
#
SELECTED_STIG_RULES=selected-stig-rules.txt
xmlstarlet sel -N "xccdf=http://checklists.nist.gov/xccdf/1.2" \
  -t -v \
  "//xccdf:Profile[@id='xccdf_org.ssgproject.content_profile_stig']/xccdf:select[@selected='true']/@idref" \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml | sort -u > $SELECTED_STIG_RULES

#
# only enable the CAT I STIG rules
#
RULES=( \
    $(comm -12 $HIGH_RULES_ONLY $SELECTED_STIG_RULES)
)
rm -f $HIGH_RULES_ONLY $SELECTED_STIG_RULES

TMPFILE=tailor-$$.sh

#
# create script to generate a new tailored STIG profile
#
cat > $TMPFILE <<'EOF'
autotailor \
    --output ssg-rhel9-ds-tailoring-high-only.xml \
    --new-profile-id xccdf_org.ssgproject.content_profile_stig_high_only \
EOF

#
# disable all the rules in the STIG profile
#
for i in $(xmlstarlet sel -N "xccdf=http://checklists.nist.gov/xccdf/1.2" \
  -t -v \
  "//xccdf:Profile[@id='xccdf_org.ssgproject.content_profile_stig']/xccdf:select[@selected='true']/@idref" \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml)
do
  echo "    -u $i \\" >> $TMPFILE
done

#
# enable only these rules
#
for rule in ${RULES[@]}
do
    sed -i "/$rule /d" $TMPFILE
    echo "    -s $rule \\" >> $TMPFILE
done

#
# provide the source datastream and profile
#
cat >> $TMPFILE <<'EOF'
    /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml \
    xccdf_org.ssgproject.content_profile_stig
EOF

chmod +x $TMPFILE

./$TMPFILE

rm -fr $TMPFILE
