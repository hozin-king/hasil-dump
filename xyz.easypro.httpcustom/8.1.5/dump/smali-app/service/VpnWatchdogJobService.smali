.class public final Ldev/epro/httpcustom/service/VpnWatchdogJobService;
.super Landroid/app/job/JobService;


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Ldev/epro/httpcustom/service/VpnWatchdogJobService$P11674755437939094346;
    }
.end annotation


# static fields
.field public static final synthetic c:I


# instance fields
.field public final a:Ldev/epro/r0/B12697158515682084892;

.field public b:Ldev/epro/r0/B13621542440076722679;


# direct methods
.method static constructor <clinit>()V
    .locals 1

    const/16 v0, 0x370

    invoke-static {v0}, Lh/prnup/fnruxh/szepgyrk;->longktebfdic0(I)V

    return-void
.end method

.method public constructor <init>()V
    .locals 1

    .line 1
    .line 2
    .line 3
    invoke-direct {p0}, Landroid/app/job/JobService;-><init>()V

    .line 4
    .line 5
    .line 6
    .line 7
    .line 8
    .line 9
    .line 10
    .line 11
    .line 12
    .line 13
    .line 14
    invoke-direct {p0}, Ldev/epro/httpcustom/service/VpnWatchdogJobService;->kfipnbpyibja()V

    return-void
.end method

.method private native kfipnbpyibja()V
.end method


# virtual methods
.method public final native a(Landroid/content/Context;Ldev/epro/r0/R11390680666373737087;Ldev/epro/r0/X353331449540260032;Ldev/epro/r0/N10548973828977060746;)Ljava/lang/Object;
.end method

.method public final native b(Landroid/content/Context;Ldev/epro/r0/N10548973828977060746;)Ljava/lang/Object;
.end method

.method public final native onDestroy()V
.end method

.method public final native onStartJob(Landroid/app/job/JobParameters;)Z
.end method

.method public final native onStopJob(Landroid/app/job/JobParameters;)Z
.end method
