# Preserve Room database constructors instantiated via reflection.
# Required for R8 Full Mode with older Room versions.
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
}
