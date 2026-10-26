# Room instantiates generated databases (e.g. WorkManager's WorkDatabase_Impl) by reflection
# through their no-arg constructor. Room < 2.7 only keeps the class, so R8 full mode strips
# the constructor and the app crashes on startup in androidx.startup.InitializationProvider.
-keep class * extends androidx.room.RoomDatabase { void <init>(); }
