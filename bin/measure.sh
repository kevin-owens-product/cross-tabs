if [ $# -eq 0 ]; then
    echo "Use like ./bin/measure.sh [files]"
    echo ""
    echo "example:"
    echo "./bin/measure.sh dist/*.js"
    exit 1
fi

for FILE in $@; do
    echo "File size of $FILE is $(cat ${FILE} | wc -c), gzipped: $(cat ${FILE} | gzip -c | wc -c)"
done
