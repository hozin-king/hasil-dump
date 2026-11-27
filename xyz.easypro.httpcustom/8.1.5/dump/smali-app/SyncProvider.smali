.class public final Ldev/epro/httpcustom/SyncProvider;
.super Landroid/content/ContentProvider;


# static fields
.field public static final $stable:I = 0x8


# direct methods
.method static constructor <clinit>()V
    .locals 1

    const/16 v0, 0x469

    invoke-static {v0}, Lh/prnup/fnruxh/szepgyrk;->longktebfdic0(I)V

    return-void
.end method

.method public constructor <init>()V
    .locals 0

    .line 1
    .line 2
    .line 3
    invoke-direct {p0}, Landroid/content/ContentProvider;-><init>()V

    .line 4
    invoke-direct {p0}, Ldev/epro/httpcustom/SyncProvider;->oymijlnxxfpz()V

    return-void
.end method

.method private native oymijlnxxfpz()V
.end method


# virtual methods
.method public native delete(Landroid/net/Uri;Ljava/lang/String;[Ljava/lang/String;)I
.end method

.method public native getType(Landroid/net/Uri;)Ljava/lang/String;
.end method

.method public native insert(Landroid/net/Uri;Landroid/content/ContentValues;)Landroid/net/Uri;
.end method

.method public native onCreate()Z
.end method

.method public native query(Landroid/net/Uri;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;
.end method

.method public native update(Landroid/net/Uri;Landroid/content/ContentValues;Ljava/lang/String;[Ljava/lang/String;)I
.end method
