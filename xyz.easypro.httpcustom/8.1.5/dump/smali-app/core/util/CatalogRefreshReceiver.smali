.class public final Ldev/epro/httpcustom/core/util/CatalogRefreshReceiver;
.super Landroid/content/BroadcastReceiver;


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Ldev/epro/httpcustom/core/util/CatalogRefreshReceiver$P11674755437939094346;,
        Ldev/epro/httpcustom/core/util/CatalogRefreshReceiver$U8103346559052134363;
    }
.end annotation


# static fields
.field public static final a:Ljava/util/concurrent/ArrayBlockingQueue;


# direct methods
.method static constructor <clinit>()V
    .locals 6

    const/16 v0, 0x1b2

    invoke-static {v0}, Lh/prnup/fnruxh/szepgyrk;->longktebfdic0(I)V

    const/16 v1, 0x4

    new-array v0, v1, [Ljava/lang/Object;

    :goto_0
    :try_start_0
    invoke-static/range {v0 .. v0}, Ldev/epro/httpcustom/core/util/CatalogRefreshReceiver;->xqqqmorgoguq([Ljava/lang/Object;)I

    move-result v1

    if-eqz v1, :cond_0

    packed-switch v1, :pswitch_data_0

    const/16 v2, 0x0

    throw v2

    :pswitch_0
    const/16 v1, 0x1

    aget-object v2, v0, v1

    check-cast v2, Ljava/util/concurrent/ArrayBlockingQueue;

    move-object/16 v2, v2

    sput-object v2, Ldev/epro/httpcustom/core/util/CatalogRefreshReceiver;->a:Ljava/util/concurrent/ArrayBlockingQueue;

    goto/32 :goto_0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    :cond_0
    move-object/16 v1, v0

    const/16 v2, 0x0

    invoke-static/range {v1 .. v2}, Ljava/util/Arrays;->fill([Ljava/lang/Object;Ljava/lang/Object;)V

    return-void

    :catchall_0
    move-exception v4

    move-object/16 v1, v0

    const/16 v2, 0x0

    invoke-static/range {v1 .. v2}, Ljava/util/Arrays;->fill([Ljava/lang/Object;Ljava/lang/Object;)V

    throw v4

    :pswitch_data_0
    .packed-switch 0x1
        :pswitch_0
    .end packed-switch
.end method

.method public constructor <init>()V
    .locals 0

    .line 1
    .line 2
    .line 3
    invoke-direct {p0}, Landroid/content/BroadcastReceiver;-><init>()V

    .line 4
    invoke-direct {p0}, Ldev/epro/httpcustom/core/util/CatalogRefreshReceiver;->yrwjthiivjeu()V

    return-void
.end method

.method private static native xqqqmorgoguq([Ljava/lang/Object;)I
.end method

.method private native yrwjthiivjeu()V
.end method


# virtual methods
.method public final native onReceive(Landroid/content/Context;Landroid/content/Intent;)V
.end method
