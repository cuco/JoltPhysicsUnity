    -DJPH_CROSS_PLATFORM_DETERMINISTIC
    -I"$JOLTC_DIR"
    -I"$JOLT_DIR"
    -isysroot "$SDKROOT"
)
{
    echo "$JOLTC_DIR/joltc.cpp"
    echo "$JOLTC_DIR/joltc_assert.cpp"
    find "$JOLT_DIR/Jolt" -name '*.cpp' | sort
} > "$RSP"
echo "Compiling $(wc -l < "$RSP") translation units..."
while IFS= read -r src; do
    rel="${src#$ROOT/}"
    obj="$OBJ_DIR/${rel//\//_}.o"
    "$CXX" "${COMMON_FLAGS[@]}" -c "$src" -o "$obj"
done < "$RSP"
OBJECTS="$(find "$OBJ_DIR" -name '*.o' | sort | tr '\n' ' ')"
echo "Linking libjoltc.dylib..."
# shellcheck disable=SC2086
"$CXX" "${COMMON_FLAGS[@]}" -dynamiclib \
    -install_name '@rpath/libjoltc.dylib' \
    -o "$OUT_DIR/libjoltc.dylib" \
    $OBJECTS
DSYM="$OUT_DIR/libjoltc.dylib.dSYM"
rm -rf "$DSYM"
dsymutil "$OUT_DIR/libjoltc.dylib" -o "$DSYM"
echo "Done: $OUT_DIR/libjoltc.dylib"
dwarfdump --uuid "$OUT_DIR/libjoltc.dylib" "$DSYM/Contents/Resources/DWARF/libjoltc.dylib"
otool -L "$OUT_DIR/libjoltc.dylib" | head -5