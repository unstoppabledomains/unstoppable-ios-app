//
//  ExternalWalleMake.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.04.2022.
//

import UIKit

enum ExternalWalletMake: String, Codable, Hashable {
    case Rainbow = "1ae92b26df02f0abca6304df07debccd18262fdf5fe82daa81593582dac9a369"
    case TrustWallet = "4622a2b2d6af1c9844944291e5e7351a6aa24cd7b23099efac1b2fd875da31a0"
    case MetaMask = "c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96"
    case AlphaWallet = "138f51c8d00ac7b9ac9d8dc75344d096a7dfe370a568aa167eabc0a21830ed98"
    case ledgerLive = "19177a98252e07ddfc9af2083ba8e07ef627cb6103467ffebb3f8f4205fd7927"
    case SparkPoint = "3b0e861b3a57e98325b82ab687fe0a712c81366d521ceec49eebc35591f1b5d1"
    case KleverWallet = "fbea6f68df4e6ce163c144df86da89f24cb244f19b53903e26aea9ab7de6393c"
    case Ellipal = "15d1d97de89526a3c259a235304a7c510c40cda3331f0f8433da860ecc528bef"
    case Autonomy = "30edc47c24de2727a86d50ba88c3516db28c0494a7c5f0b127e4329e855c6840"
    case Avacus = "2969649937a2a6c587e1391446d60e2e06b9c5196162a6aa70a0002292aa8d22"
    case LOBSTRWallet = "76a3d548a08cf402f5c7d021f24fd2881d767084b387a5325df88bc3d4b6f21b"
    case SONEWallet = "114efdbef4ce710081c1507f3dbc51f439c96a342cf33397799cd1c84b01a8c5"
    case SafePal = "0b415a746fb9ee99cce155c2ceca0c6f6061b1dbca2d722b3ba16381d0562150"
    case MYKEY = "61f6e716826ae8455ad16abc5ec31e4fd5d6d2675f0ce2dee3336335431f720e"
    case EdgeWallet = "0c5bba82e70a2b62405871af809020a077d110d765c0798eb660ad5d3131b328"
    case EasyPocket = "244a0d93a45df0d0501a9cb9cdfb4e91aa750cfd4fc88f6e97a54d8455a76f5c"
    case Stasis = "9d6c614d1995741d5313f1f3dbf1f66dcba694de782087d13b8721822502692f"
    case TKFinance = "e3787ea98d014ca77e2c3794db97c02ef8bcb39347705f5e79502a55434a1ecf"
    case TKFinance2 = "add8361c0692500217aea81380a8dd4b4d7ce6458292391957c874630c80b874"
    case CYBAVOWallet = "a395dbfc92b5519cbd1cc6937a4e79830187daaeb2c6fcdf9b9cce4255f2dcd5"
    case JulWallet = "a6ffb821a3c32d36fc9d29e29c2ff79a0cd1db0bca453714777846ddf3fdff76"
    case Nash = "8240fb8a7b117aed27f04aa8870c714eeb910f7c1b16c9b868e793c1836335b8"
    case LeadWallet = "33e181cb6c0f3e313e20b17129f06f4dd9939a01e3a371cdef389d4dcc29258e"
    case KEYRINGPRO = "0fa0f603076de79bbac9a4d47770186de8913da63c8a4070c500a783cddbd1e3"
    case NeftiWallet = "91628e2ae2228af2145bfac21093ad7be682810ec16af540a9e017ad6b933a81"
    case MathWallet = "7674bb4e353bf52886768a3ddc2a4562ce2f4191c80831291218ebd90f5f5e26"
    case KryptoGOWallet = "19418ecfd44963883e4d6abca1adeb2036f3b5ffb9bee0ec61f267a9641f878b"
    case fuseCash = "c20b97dd1679625f4eb0bccd727c80746cb13bd97208b0c8e62c89cfd1d4b9cc"
    case DCENTWallet = "468b4ab3582757233017ec10735863489104515ab160c053074905a1eecb7e63"
    case ElastosEssentials = "717911f4db0c5eda0e02e76ed179b7940ba1eefffdfb3c9e6540696226860da0"
    case Valora = "d01c7758d741b363e637a817a09bcf579feae4db9f5bb16f599fdd1f66e2f974"
    case CoinStats = "7e94e75c90964a69ea375b92214f50c4223dfbfa4913a3733b615444b322f687"
    case Orange = "d864d048f82084fac88d386c32b3261513ed7b5d1d4b52f96f91022059e984f9"
    case RWallet = "b13fcc7e3500a4580c9a5341ed64c49c17d7f864497881048eb160c089be5346"
    case OneinchWallet = "2863183c3299d820fb9a4cb8aab4a34f50380c9992e8be871fd60a62e8d36481"
    case PlasmaPay = "13c6a06b733edf51784f669f508826b2ab0dc80122a8b5d25d84b17d94bbdf70"
    case CryptoComDeFiWallet = "f2436c67184f158d1beda5df53298ee84abfc367581e4505134b5bcf5f46697d"
    case SafeMoon = "b265ce38b94d602957a0946673c59a99a15d69adda4317544fec7298ea2d1387"
    case BitPay = "ccb714920401f7d008dbe11281ae70e3a4bfb621763b187b9e4a3ce1ab8faa3b"
    case O3Wallet = "0aafbedfb8eb56dae59ecc37c9a5388509cf9c082635e3f752581cc7128a17c0"
    case ONTO = "dceb063851b1833cbb209e3717a0a0b06bf3fb500fe9db8cd3a553e4b1d02137"
    case ZelCore = "29f4a70ad5993f3f73ae8119f0e78ecbae51deec2a021a770225c644935c0f09"
    case BridgeWallet = "881946407ff22a32ec0e42b2cd31ea5dab52242dc3648d777b511a0440d59efb"
    case Coingrig = "5859076ade608fbc4e9d3fe2f95e8527de80f8451ecbb1dced54ca84deae0dd6"
    case FlareWallet = "d612ddb7326d7d64428d035971b82247322a4ffcf126027560502eff4c02bd1c"
    case Coinomi = "15d7610042217f691385d20e640869dc7273e991b04e8f476417cdc5ec856955"
    case ATokenWallet = "6193353e17504afc4bb982ee743ab970cd5cf842a35ecc9b7de61c150cf291e0"
    case TongueWallet = "4e6af4201658b52daad51a279bb363a08b3927e74c0f27abeca3b0110bddf0a9"
    case Eidoo = "efba9ae0a9e0fdd9e3e055ddf3c8e75f294babb8aea3499456eff27f771fda61"
    case Tangem = "76745388a50e6fea982c4dee2a3ad61a8aa417668be870754689caa8a7506c93"
    case Coin98 = "b021913ba555948a1c81eb3d89b372be46f8354e926679de648e4fa2938bed3e"
    case KyberSwap = "2ed796df33fdbde6a3ea6a47d3636b8341fe285038d844c7a78267b465b27028"
    case PEAKDEFIWallet = "38ee551a01e3c5af9d8a9715768861e4d642e2381a62245083f96672b5646c6b"
    case Guarda = "c04ae532094873c054a6c9339746c39c9ba5839c4d5bb2a1d9db51f9e5e77266"
    case Atomic = "185850e869e40f4e6c59b5b3f60b7e63a72e88b09e2a43a40b1fd0f237e49e9a"
    case Argent = "cf21952a9bc8108bf13b12c92443751e2cc388d27008be4201b92bbc6d83dd46"
    case Blockchain = "9806e241053d8c99b0ce9f62606f97d405de5c3c0b2593921f5aac99ecbaea58"
    case Spot = "74f8092562bd79675e276d8b2062a83601a4106d30202f2d509195e30e19673d"
    case imToken = "9d373b43ad4d2cf190fb1a774ec964a1addf406d6fd24af94ab7596e58c291b2"
    case Zelus = "00e39f835988d1bb783b2a0748e18bc6278dec03492d00b0e102a466cd8b3d77"
    case Omni = "afbd95522f4041c71dd4f1a065f971fd32372865b416f95a0b1db759ae33f2a7"
    case Exodus = "e9ff15be73584489ca4a66f64d32c4537711797e30b6660dbcb71ea72a42b1f4"
    case Zerion = "ecc4036f814562b41a5268adc86270fba1365471402006302e70169465b7ac18"
    case Mew = "f5b4eeb6015d66be3f5940a895cbaa49ef3439e518cd771270e6b553b48f31d2"
}

extension ExternalWalletMake {        
    var icon: UIImage {
        switch self {
        case .MetaMask: return UIImage(named: "walletMetaMask")!
        case .Rainbow: return UIImage(named: "walletRainbow")!
        case .TrustWallet: return UIImage(named: "walletTrust")!
        case .MathWallet: return UIImage(named: "walletMath")!
        case .AlphaWallet: return UIImage(named: "walletAlpha")!
        case .ONTO: return UIImage(named: "walletOnto")!
        case .ledgerLive: return UIImage(named: "walletLedger")!
        case .KleverWallet: return .cancelCircleIcon
        case .Guarda: return .cancelCircleIcon
        case .Atomic: return .cancelCircleIcon
        case .Coinomi: return .cancelCircleIcon
        case .Coin98: return .cancelCircleIcon
        case .Argent: return .cancelCircleIcon
        case .Blockchain: return .cancelCircleIcon
        case .Spot: return UIImage(named: "walletSpot")!
        case .imToken: return .cancelCircleIcon
        case .Zelus: return UIImage(named: "walletZelus")!
        case .Omni: return UIImage(named: "walletOmni")!
        case .Exodus: return .cancelCircleIcon
        case .CryptoComDeFiWallet: return UIImage(named: "walletCryptoComDeFi")!
        case .Zerion: return UIImage(named: "walletZerion")!
        case .Mew: return .cancelCircleIcon
        default: return .init()
        }
    }
    
    var appStoreId: String? {
        switch self {
        case .MetaMask: return "id1438144202"
        case .Rainbow: return "id1457119021"
        case .TrustWallet: return "id1288339409"
        case .MathWallet: return "id1582612388"
        case .AlphaWallet: return "id1358230430"
        case .ONTO: return "id1436009823"
        case .ledgerLive: return "id1361671700"
        case .KleverWallet: return "id1525584688"
        case .Guarda: return "id1442083982"
        case .Atomic: return "id1478257827"
        case .Coinomi: return "id1333588809"
        case .Coin98: return "id1561969966"
        case .Argent: return "id1358741926"
        case .Blockchain: return "id493253309"
        case .CryptoComDeFiWallet: return "id1512048310"
        case .Zerion: return "id1456732565"
        case .Omni: return "id1569375204"
        case .Zelus: return "id1588430343"
        case .Exodus: return "id1414384820"
        case .Spot: return "id1390560448"
        case .Mew: return "id1464614025"
        default: return .init()
        }
    }
    
    var isRecommended: Bool {
        switch self {
        case .MetaMask, .TrustWallet:
            return true
        default:
            return false
        }
    }
}
