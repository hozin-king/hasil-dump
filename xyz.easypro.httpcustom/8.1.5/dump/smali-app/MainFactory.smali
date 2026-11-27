.class public final Ldev/epro/httpcustom/MainFactory;
.super Landroid/app/AppComponentFactory;


# static fields
.field public static final $stable:I = 0x8


# direct methods
.method static constructor <clinit>()V
    .locals 1

    const/16 v0, 0x509

    invoke-static {v0}, Lh/prnup/fnruxh/szepgyrk;->longktebfdic0(I)V

    return-void
.end method

.method public constructor <init>()V
    .locals 0

    .line 1
    .line 2
    .line 3
    invoke-direct {p0}, Landroid/app/AppComponentFactory;-><init>()V

    .line 4
    invoke-direct {p0}, Ldev/epro/httpcustom/MainFactory;->pnebrjbdorvj()V

    return-void
.end method

.method private native pnebrjbdorvj()V
.end method


# virtual methods
.method public native instantiateActivity(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Intent;)Landroid/app/Activity;
.end method

.method public native instantiateApplication(Ljava/lang/ClassLoader;Ljava/lang/String;)Landroid/app/Application;
.end method

.method public native instantiateClassLoader(Ljava/lang/ClassLoader;Landroid/content/pm/ApplicationInfo;)Ljava/lang/ClassLoader;
.end method

.method public native instantiateProvider(Ljava/lang/ClassLoader;Ljava/lang/String;)Landroid/content/ContentProvider;
.end method

.method public native instantiateReceiver(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Intent;)Landroid/content/BroadcastReceiver;
.end method

.method public native instantiateService(Ljava/lang/ClassLoader;Ljava/lang/String;Landroid/content/Intent;)Landroid/app/Service;
.end method
