.class public final Ldev/epro/httpcustom/feature/ipfinder/assist/AssistDroidSessionService;
.super Landroid/service/voice/VoiceInteractionSessionService;


# direct methods
.method static constructor <clinit>()V
    .locals 1

    const/16 v0, 0x4b0

    invoke-static {v0}, Lh/prnup/fnruxh/szepgyrk;->longktebfdic0(I)V

    return-void
.end method

.method public constructor <init>()V
    .locals 0

    .line 1
    .line 2
    .line 3
    invoke-direct {p0}, Landroid/service/voice/VoiceInteractionSessionService;-><init>()V

    .line 4
    invoke-direct {p0}, Ldev/epro/httpcustom/feature/ipfinder/assist/AssistDroidSessionService;->andahynausot()V

    return-void
.end method

.method private native andahynausot()V
.end method


# virtual methods
.method public final native onNewSession(Landroid/os/Bundle;)Landroid/service/voice/VoiceInteractionSession;
.end method
