#!/bin/bash

# change these variables to fit your system
DP2="`echo ~/daisy-pipeline/cli/dp2`" # path to dp2 command line interface
TARGET="/media/500GB/tmp/nordic-epub3-dtbook-migrator" # use this directory to store results
SOURCE="/media/500GB/DTBook" # read *.xml files in this directory and its subdirectories

mkdir -p "$TARGET/zip"
mkdir -p "$TARGET/log"
mkdir -p "$TARGET/epub"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SUBSTR_LENGTH="`expr ${#TARGET} + 1`"
SCRIPT_1="nordic-dtbook-validate"
SCRIPT_2="nordic-dtbook-to-epub3"
SCRIPT_3="nordic-epub3-validate"
SCRIPT_4="nordic-epub3-to-dtbook"
LOGFILE="$TARGET/report-`date -I`.html"
SOURCE_DTBOOKS=(`find "$SOURCE" -type f | grep \.xml$`)
SOURCE_DTBOOK_COUNT="${#SOURCE_DTBOOKS[@]}"
PROGRESSBAR_INCREMENTS=`calc "100/($SOURCE_DTBOOK_COUNT*4)" | sed 's/\~//'`

rm "$LOGFILE"
echo "Writing output to $LOGFILE"
function log {
    echo "$1" >> "$LOGFILE"
}

function html_h1 {
    log "<h1>$1</h1>"
}

function html_h2 {
    log "<h2>$1</h2>"
}

function html_h3 {
    log "<h3>$1</h3>"
}

function html_tr {
    log "<tr>"
}

function html_tr_end {
    log "</tr>"
}

function html_td {
    if [ "$1" == "DONE" ]; then
        log "<td class=\"success\"><ul>"
    else
        if [ "$1" == "VALIDATION_FAIL" ]; then
            log "<td class=\"danger\"><ul>"
        else
            log "<td class=\"$1\"><ul>"
        fi
    fi
}

function html_td_end {
    log "</ul></td>"
}

function html_li {
    if [ "$2" == "" ]; then
        log "<li>$1</li>"
    else
        log "<li><a href=\"$2\">$1</a></li>"
    fi
}

log "<!DOCTYPE html>"
log "<html lang=\"en\">"
log "<head>"
log "    <meta encoding=\"utf-8\"/>"
log "    <title>Nordic EPUB3/DTBook batch conversion</title>"
log "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />"
log "    <style type=\"text/css\""
cat $DIR/bootstrap.min.css >> $LOGFILE
log "    </style>"
log "    <style>.nobr { white-space:nowrap; }</style>"
log "</head>"
log "<body class=\"content\">"
log "    <div class=\"container\">"
log "        <h1>Nordic EPUB3/DTBook batch conversion</h1>"
log "        <p>Start time: `date`</p>"
log "        <p>DTBook files: $SOURCE_DTBOOK_COUNT</p>"
log "<div class=\"progress progress-striped active\">"
log "  <div id=\"progress-done\" class=\"progress-bar progress-bar-success\" role=\"progressbar\" aria-valuenow=\"0\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: 0%;\">"
log "    <span><span id=\"progress-done-count\">0</span> DONE</span>"
log "  </div>"
log "  <div id=\"progress-failed\" class=\"progress-bar progress-bar-danger\" role=\"progressbar\" aria-valuenow=\"0\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: 0%;\">"
log "    <span><span id=\"progress-failed-count\">0</span> FAILED</span>"
log "  </div>"
log "  <div id=\"progress-skipped\" class=\"progress-bar progress-bar-warning\" role=\"progressbar\" aria-valuenow=\"0\" aria-valuemin=\"0\" aria-valuemax=\"100\" style=\"width: 0%;\">"
log "    <span><span id=\"progress-skipped-count\">0</span> SKIPPED</span>"
log "  </div>"
log "</div>"
log "        <table width=\"100%\" class=\"table table-bordered table-hover table-condensed\">"
log "<thead><tr>"
log "<th class=\"nobr\">Book ID</th>"
log "<th class=\"nobr\">$SCRIPT_1</th>"
log "<th class=\"nobr\">$SCRIPT_2</th>"
log "<th class=\"nobr\">$SCRIPT_3</th>"
log "<th class=\"nobr\">$SCRIPT_4</th>"
log "</tr></thead><tbody>"

PROGRESS_DONE_COUNT=0
PROGRESS_SKIPPED_COUNT=0
PROGRESS_FAILED_COUNT=0
function update_progress {
    STATUS="$1"
    COUNT=0
    if [ "$STATUS" == "DONE" ]; then
        STATUS="done"
        PROGRESS_DONE_COUNT=`calc $PROGRESS_DONE_COUNT + 1`
        COUNT=$PROGRESS_DONE_COUNT
    else
        if [ "$STATUS" == "SKIPPED" ]; then
            STATUS="skipped"
            PROGRESS_SKIPPED_COUNT=`calc $PROGRESS_SKIPPED_COUNT + 1`
            COUNT=$PROGRESS_SKIPPED_COUNT
        else
            STATUS="failed"
            PROGRESS_FAILED_COUNT=`calc $PROGRESS_FAILED_COUNT + 1`
            COUNT=$PROGRESS_FAILED_COUNT
        fi
    fi
    PROGRESS="`calc "$PROGRESSBAR_INCREMENTS * $COUNT" | sed 's/\~//'`"
    log "<script type=\"text/javascript\">"
    log "document.getElementById('progress-$STATUS').setAttribute('aria-valuenow','$PROGRESS');"
    log "document.getElementById('progress-$STATUS').setAttribute('style','width: $PROGRESS%;');</script>"
    log "<script type=\"text/javascript\">document.getElementById('progress-$STATUS-count').innerHTML = '$COUNT';"
    log "</script>"
}

function nordic_test {
    # takes two parameters; first the id, then the full file path
    html_tr
    log "<td><strong>$1</strong></td>"
    
    STATUS_1=""
    STATUS_2=""
    STATUS_3=""
    STATUS_4=""
    
    if [ -f "$2" ]; then
        $DP2 $SCRIPT_1 --x-no-legacy="false" --x-dtbook="$2" --output="$TARGET/zip/$1.$SCRIPT_1.zip" -p
        $DP2 log --lastid --file="$TARGET/log/$1.$SCRIPT_1.log"
        mkdir -p "$TARGET/zip/$1.$SCRIPT_1"
        unzip -o "$TARGET/zip/$1.$SCRIPT_1.zip" -d "$TARGET/zip/$1.$SCRIPT_1/"
        STATUS_1="`$DP2 status --lastid | grep Status | sed 's/.*Status: //'`"
        update_progress $STATUS_1
        HTML_1="`find "$TARGET/zip/$1.$SCRIPT_1/html-report/" -type f | head -n 1 |  sed -r "s/^.{$SUBSTR_LENGTH}//"`"
        LOG_1="`echo "$TARGET/log/$1.$SCRIPT_1.log" | sed -r "s/^.{$SUBSTR_LENGTH}//"`"
        html_td "$STATUS_1"
        html_li "Status: $STATUS_1"
        html_li "HTML report" "$HTML_1"
        html_li "detailed log" "$LOG_1"
        html_li "`basename $2`" "$2"
        html_td_end
        $DP2 delete --lastid
        
        if [ "$STATUS_1" == "DONE" ]; then
            $DP2 $SCRIPT_2 --x-no-legacy="false" --x-strict="false" --x-dtbook="$2" --output="$TARGET/zip/$1.$SCRIPT_2.zip" -p
            $DP2 log --lastid --file="$TARGET/log/$1.$SCRIPT_2.log"
            mkdir -p "$TARGET/zip/$1.$SCRIPT_2"
            unzip -o "$TARGET/zip/$1.$SCRIPT_2.zip" -d "$TARGET/zip/$1.$SCRIPT_2/"
            STATUS_2="`$DP2 status --lastid | grep Status | sed 's/.*Status: //'`"
            update_progress $STATUS_2
            LOG_2="`echo "$TARGET/log/$1.$SCRIPT_2.log" | sed -r "s/^.{$SUBSTR_LENGTH}//"`"
            HTML_2="`find "$TARGET/zip/$1.$SCRIPT_2/html-report/" -type f | head -n 1 |  sed -r "s/^.{$SUBSTR_LENGTH}//"`"
            html_td "$STATUS_2"
            html_li "Status: $STATUS_2"
            html_li "HTML report" "$HTML_2"
            html_li "detailed log" "$LOG_2"
            html_li "`basename $2`" "$2"
            html_td_end
            $DP2 delete --lastid
        else
            html_td
            html_li "Status: SKIPPED"
            update_progress "SKIPPED"
            html_td_end
        fi
        
        if [ "$STATUS_2" == "DONE" ]; then
            EPUB="`find $TARGET/zip/$1.$SCRIPT_2/ -type f | grep epub\$`"
            $DP2 $SCRIPT_3 --x-strict="false" --x-epub="$EPUB" --output="$TARGET/zip/$1.$SCRIPT_3.zip" -p
            $DP2 log --lastid --file="$TARGET/log/$1.$SCRIPT_3.log"
            mkdir -p "$TARGET/zip/$1.$SCRIPT_3"a
            unzip -o "$TARGET/zip/$1.$SCRIPT_3.zip" -d "$TARGET/zip/$1.$SCRIPT_3/"
            STATUS_3="`$DP2 status --lastid | grep Status | sed 's/.*Status: //'`"
            update_progress $STATUS_3
            LOG_3="`echo $TARGET/log/$1.$SCRIPT_3.log | sed -r "s/^.{$SUBSTR_LENGTH}//"`"
            HTML_3="`find "$TARGET/zip/$1.$SCRIPT_3/html-report/" -type f | head -n 1 |  sed -r "s/^.{$SUBSTR_LENGTH}//"`"
            html_td "$STATUS_3"
            html_li "Status: $STATUS_3"
            html_li "HTML report" "$HTML_3"
            html_li "detailed log" "$LOG_3"
            html_li "`basename $EPUB`" "$EPUB"
            html_td_end
            $DP2 delete --lastid
        else
            html_td
            html_li "Status: SKIPPED"
            update_progress "SKIPPED"
            html_td_end
        fi
        
        if [ "$STATUS_3" == "DONE" ]; then
            EPUB="`find $TARGET/zip/$1.$SCRIPT_2/ -type f | grep epub\$`"
            $DP2 $SCRIPT_4 --x-strict="false" --x-epub="$EPUB" --output="$TARGET/zip/$1.$SCRIPT_4.zip" -p
            $DP2 log --lastid --file="$TARGET/log/$1.$SCRIPT_4.log"
            mkdir -p "$TARGET/zip/$1.$SCRIPT_4"
            unzip -o "$TARGET/zip/$1.$SCRIPT_4.zip" -d "$TARGET/zip/$1.$SCRIPT_4/"
            STATUS_4="`$DP2 status --lastid | grep Status | sed 's/.*Status: //'`"
            update_progress $STATUS_4
            LOG_4="`echo $TARGET/log/$1.$SCRIPT_4.log | sed -r "s/^.{$SUBSTR_LENGTH}//"`"
            HTML_4="`find "$TARGET/zip/$1.$SCRIPT_4/html-report/" -type f | head -n 1 |  sed -r "s/^.{$SUBSTR_LENGTH}//"`"
            html_td "$STATUS_4"
            html_li "Status: $STATUS_4"
            html_li "HTML report" "$HTML_4"
            html_li "detailed log" "$LOG_4"
            html_li "`basename $EPUB`" "$EPUB"
            html_td_end
            $DP2 delete --lastid
        else
            html_td
            html_li "Status: SKIPPED"
            update_progress "SKIPPED"
            html_td_end
        fi
        
    else
        html_td "danger"
        html_li "Status: SKIPPED"
        html_li "DTBook not found: $2"
        update_progress "SKIPPED"
        update_progress "SKIPPED"
        update_progress "SKIPPED"
        update_progress "SKIPPED"
        html_td_end
    fi
    
    html_tr_end
}

# iterate over all DTBooks
for dtbook in "${SOURCE_DTBOOKS[@]}"
do
    dtbook_path="${dtbook}"
    dtbook_id=`echo $dtbook_path | sed -r 's/^.*\/(.*)\.xml/\1/'`
    nordic_test "$dtbook_id" "$dtbook_path"
done

# finishing the log file
log "</tbody></table>"
log "<p>Finish time: `date`</p>"
log "</div>"
log "</body></html>"

cp "$LOGFILE" "$TARGET/report.html"

echo "Report file: $LOGFILE"
