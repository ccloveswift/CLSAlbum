//
//  CLSCameraMgr.swift
//  CLSCamera
//
//  Created by TT on 2017/5/13.
//  Copyright © 2017年 TT. All rights reserved.
//

import UIKit
import Photos
import CLSCommon

open class CLSAlbumMgr: NSObject {

    public static let instance = CLSAlbumMgr()
    
    var kHCAlbumName: String?
    
    /**
     *  当mAllPhotos 有改变时通知
     */
    static let kNotification_AllPhotosChanged = "kNotification_AllPhotosChanged"
    static let kNotification_AllSectionsChanged = "kNotification_AllSectionsChanged"
    
    /**
     *  相册照片
     */
    
    private var _mAllPhotos: PHFetchResult<PHAsset>!
    public var mAllPhotos: PHFetchResult<PHAsset>! {
        
        get { return _mAllPhotos }
        set {
            
            _mAllPhotos = newValue
            
            DispatchQueue.main.async {
                
                NotificationCenter.default.post(name: NSNotification.Name(CLSAlbumMgr.kNotification_AllPhotosChanged), object: nil)
            }
        }
    }
    
    /**
     *  用于查询PHAsset
     */
    private lazy var _mPHCachingImageMgr = PHCachingImageManager.default()
    
    private lazy var mSmallOptions: PHImageRequestOptions = {
        
        let opt = PHImageRequestOptions.init()
        opt.resizeMode = .fast
        opt.isSynchronous = true
        opt.deliveryMode = .fastFormat
        opt.isNetworkAccessAllowed = false
        return opt
    }()
    
    internal override init() {
        
        super.init()
        
        let opt = PHFetchOptions()
        opt.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.mAllPhotos = PHAsset.fetchAssets(with: opt)
        
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    
    /** 查询一张图 */
    public func fGetSmallItemImage(for asset: PHAsset, targetSize: CGSize, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        let options = mSmallOptions
        return _mPHCachingImageMgr.requestImage(for: asset, targetSize: targetSize, contentMode: PHImageContentMode.aspectFill, options: options, resultHandler: {(img: UIImage?, info: [AnyHashable : Any]?) -> Void in
            
            resultHandler(img, info)
        })
    }
    
    /** 取消查询 */
    public func fCancelImageRequest(requestID: PHImageRequestID?) {
        
        if requestID != nil {
            
            _mPHCachingImageMgr.cancelImageRequest(requestID!)
        }
    }
    
    /** 删除一张图 */
    public func fDeleteImage(for asset: PHAsset, completionHandler: ((Bool, Error?) -> Void)?) {
        
        PHPhotoLibrary.shared().performChanges({
            
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
            
        }, completionHandler: completionHandler)
    }
    
    /// 获取原始图片
    ///
    /// - Parameters:
    ///   - asset: PHAsset
    ///   - progress: 下载iCould进度
    ///   - resultHandler: 拿到图片
    public func fGetOriginImage(for asset: PHAsset, progressHandler progress: PHAssetImageProgressHandler?, completeHandler resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        
        let options = PHImageRequestOptions.init()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        options.progressHandler = progress
        options.resizeMode = .none
        return _mPHCachingImageMgr.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: options, resultHandler: {(img: UIImage?, info: [AnyHashable : Any]?) -> Void in
            
            resultHandler(img, info)
        })
    }
    
    
    /// 获取所有相册信息
    ///
    /// - Returns: 所有相册
    public func fGetAllCollections() -> PHFetchResult<PHAssetCollection> {
        
        let opt = PHFetchOptions()
//        opt.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                  subtype: .albumRegular,
                                                                  options: opt)
        return smartAlbums
    }
    
    public func fGetSystemsAndUserCollections() -> [PHAssetCollection] {
        
        var arrCollections = [PHAssetCollection]()
        
        let systemCollections = fGetAllCollections()
        for i in 0 ..< systemCollections.count {
            
            let collection = systemCollections.object(at: i)
            if collection.localizedTitle == "Camera Roll" {
                
                arrCollections.append(collection)
            }
//            print("\(collection.localizedTitle)")
        }
        for i in 0 ..< systemCollections.count {
            
            let collection = systemCollections.object(at: i)
            if collection.localizedTitle == "Favorites" {
                
                arrCollections.append(collection)
            }
        }
        
        let allUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        for i in 0 ..< allUserCollections.count {
            
            arrCollections.append(allUserCollections.object(at: i) as! PHAssetCollection)
        }
        
        return arrCollections
    }
    
    /// 获取当前相册第一张图片
    ///
    /// - Parameter collection: 相册
    /// - Returns: 放回图片
    public func fGetPHAssetsFromCollection(collection: PHAssetCollection) -> PHFetchResult<PHAsset> {
        
        let opt = PHFetchOptions.init()
        opt.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        opt.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        let asset = PHAsset.fetchAssets(in: collection, options: opt)
        return asset
    }
    
    /// 获取并创建当前 相册
    private var _mAssetCollection: PHAssetCollection?
    var mAssetCollection: PHAssetCollection? {
        get {
            
            guard (kHCAlbumName != nil) else {
                
                assert(false)
                return nil
            }
            
            if _mAssetCollection == nil {
                
                let AlbumName = kHCAlbumName!
                // 查询相册
                let opt = PHFetchOptions.init()
                if #available(iOS 9.0, *) {
                    opt.fetchLimit = 1
                }
                opt.predicate = NSPredicate.init(format: "%K = %@", "localizedTitle", AlbumName)
                let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: opt)
                for i in 0 ..< result.count {
                    
                    let cos = result.object(at: i)
                    if cos.localizedTitle == kHCAlbumName {
                        
                        _mAssetCollection = cos
                        break
                    }
                }
                
                if _mAssetCollection == nil {
                    
                    // 创建相册
                    var localIdentifier: String!
                    try? PHPhotoLibrary.shared().performChangesAndWait {
                        
                        localIdentifier = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: AlbumName).placeholderForCreatedAssetCollection.localIdentifier
                    }
                    
                    _mAssetCollection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil).firstObject
                }
            }
            
            return _mAssetCollection
        }
    }
    
    // MARK: 保存图片到系统相册
    /// 保存一张图片到系统相册 和 HC相册
    ///
    /// - Parameters:
    ///   - img: 图片带 exif
    ///   - completion: 完成回调，可能保存失败
    private func fSavePhoto(img: UIImage, _ completion:((Bool, Error?) -> Void)?) {
        
        // 先保存在系统相册，在保存在HC相册
        var assetIdentifier: String?
        PHPhotoLibrary.shared().performChanges({
            
            // 保存到系统相册
            assetIdentifier = PHAssetChangeRequest.creationRequestForAsset(from: img).placeholderForCreatedAsset?.localIdentifier
            
        }, completionHandler: {(suc: Bool, err: Error?) in
            
            if suc == false {
                
//                print("pSavePhoto  error  =  \(err)")
                if (completion != nil) { completion! (suc, err)}
                return
            }
            
            // 获取HC相册
            let col = self.mAssetCollection
            if col == nil {
                
                assert(false)
                if (completion != nil) { completion! (false, err)}
                return
            }
            
            if assetIdentifier == nil {
                
                assert(false)
                if (completion != nil) { completion! (false, err)}
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                
                let asset: PHAsset? = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier!], options: nil).firstObject
                let request = PHAssetCollectionChangeRequest.init(for: col!)
                if asset != nil {
                    
                    let enumeration: NSArray = [asset!]
                    request?.addAssets(enumeration)
                }
                
            }, completionHandler: { (suc2: Bool, err2: Error?) in
                
                if (suc2 == false) {
                    
//                    print("图片保存失败 error  =  \(err2)")
                }
                else {
                    
//                    print("图片保存成功")
                }
                
                if (completion != nil) { completion!(suc2, err2) }
            })
        })
    }
    
    // MARK: 获取当前权限
    
    /// 获取权限
    ///
    /// - Parameter block: status == authorized 表示可以访问相册
    public func fGetAuthorizationStatus(_ block: @escaping (_ status: PHAuthorizationStatus) -> Void) {
        
        PHPhotoLibrary.requestAuthorization(block)
    }
}

// 当照片有更新时，通知
extension CLSAlbumMgr: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Check each of the three top-level fetches for changes.
            
            if let changeDetails = changeInstance.changeDetails(for: mAllPhotos) {
                // Update the cached fetch result.
                mAllPhotos = changeDetails.fetchResultAfterChanges
            }
        }
    }
}

