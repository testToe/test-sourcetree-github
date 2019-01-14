//
//  GridCollectionViewLayout.swift
//  StickyGridCollectionView-Starter
//
//  Created by Vadim Bulavin on 10/1/18.
//  Copyright © 2018 Vadim Bulavin. All rights reserved.
//

//Test
import UIKit

class StickyGridCollectionViewLayout: UICollectionViewFlowLayout {
    
    private var allAttributes: [[UICollectionViewLayoutAttributes]] = []
    
    private var contentSize = CGSize.zero
    
    /// collection viewのsectionsと同様
    private var rowsCount: Int {
        return collectionView!.numberOfSections
    }
    
    /// collection viewのitemsと同様
    private func columnsCount(in row: Int) -> Int {
        return collectionView!.numberOfItems(inSection: row)
    }
    
    /// コンテンツに該当してスクロールする為
    override var collectionViewContentSize: CGSize {
        return contentSize
    }
    
    // スクロールする時固定表示する列数
    var stickyColumnsCount = 0 {
        didSet {
            invalidateLayout()
        }
    }
    
    // collection viewから渡されたvisible rectangleに対してのattributesを用意する
    // ※collection viewのパフォーマンスに影響ある関数
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        
        for rowAttrs in allAttributes {
            for itemAttrs in rowAttrs where rect.intersects(itemAttrs.frame) {
                layoutAttributes.append(itemAttrs)
            }
        }
        
        // visible cellsに対してのカスタムattributes配列を返却
        return layoutAttributes
    }
    
    // collection view layoutが何か変化するたびに呼ばれる関数
    // 対象の全てのattributesを設定する
    override func prepare() {
        // attributes設定
        setupAttributes()
        
        // 固定列の位置を設定する
        updateStickyItemsPositions()
        
        let lastItemFrame = allAttributes.last?.last?.frame ?? .zero
        contentSize = CGSize(width: lastItemFrame.maxX, height: lastItemFrame.maxY)
    }
    
    // attributes設定
    private func setupAttributes() {
        
        // 全てのattributesを初期化
        allAttributes = []
        
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        
        // 全ての行をループする
        for row in 0..<rowsCount {
            
            // 各行のattributesを格納する配列を初期化
            var rowAttrs: [UICollectionViewLayoutAttributes] = []
            // 各行の位置が0から始まるように初期化
            xOffset = 0
            
            // １行にある全ての列をループする
            for col in 0..<columnsCount(in: row) {
                
                // １セルのframeサイズを計算する
                let itemSize = size(forRow: row, column: col)
                let indexPath = IndexPath(row: row, column: col)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                // xOffset, yOffsetで位置を正しくさせる
                attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemSize.width, height: itemSize.height).integral
                
                rowAttrs.append(attributes)
                
                // セルの横幅からxOffsetを計算する
                xOffset += itemSize.width
            }
            
            // 最後の位置と高さから次のyOffsetを計算する
            yOffset += rowAttrs.last?.frame.height ?? 0.0
            
            // 行全てのattributesを格納する
            allAttributes.append(rowAttrs)
        }
    }
    
    /**
     flow layout delegateを使用して１セルのサイズを返却する
     
     - Parameters:
        - row: マーカリストの行
        - column: マーカリストの列
     */
    private func size(forRow row: Int, column: Int) -> CGSize {
        guard let delegate = collectionView?.delegate as? UICollectionViewDelegateFlowLayout,
            let size = delegate.collectionView?(collectionView!, layout: self, sizeForItemAt: IndexPath(row: row, column: column)) else {
                assertionFailure("Implement collectionView(_,layout:,sizeForItemAt: in UICollectionViewDelegateFlowLayout")
                return .zero
        }
        
        return size
    }
    
    /**
     スクロールする際、固定列のセルを正しく位置させる為のシステム関数
     
     - Parameters:
        - newBounds: collection viewから渡されるパラメータ
     */
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    /**
     固定列の位置を設定する
     */
    private func updateStickyItemsPositions() {
        
        // 全ての行と列をループする
        for row in 0..<rowsCount {
            for col in 0..<columnsCount(in: row) {
                
                // 上段で設定済みの、対象セルのattributesを取得
                let attributes = allAttributes[row][col]
                
                // 固定列数通り、各セルの位置を設定する
                if col < stickyColumnsCount {
                    var frame = attributes.frame
                    frame.origin.x += collectionView!.contentOffset.x
                    attributes.frame = frame
                }
                
                // 固定セルがいつも他セルの上になるように z indexを設定
                attributes.zIndex = zIndex(forRow: row, column: col)
            }
        }
    }
    
    /**
     固定セルが他セルの上になるようにz orderを返却
     */
    private func zIndex(forRow row: Int, column col: Int) -> Int {
        
        // 固定セルの場合
        if col < stickyColumnsCount {
            return ZOrder.stickyItem
            
        // 固定セル以外のセルの場合
        } else {
            return ZOrder.commonItem
        }
    }
    
    // MARK: - ZOrder
    private enum ZOrder {
        static let commonItem = 0
        static let stickyItem = 1
    }

}

/**
 rowとcolumnをindexとして変換
 */
private extension IndexPath {
    init(row: Int, column: Int) {
        self = IndexPath(item: column, section: row)
    }
}
