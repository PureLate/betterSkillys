package kabam.rotmg.game.view.components {
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.objects.ObjectLibrary;
import com.company.assembleegameclient.ui.Scrollbar;
import com.company.assembleegameclient.account.ui.TextInputField;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import kabam.rotmg.market.content.MemMarketItem;
import kabam.rotmg.market.utils.GeneralUtils;
import com.company.assembleegameclient.ui.Scrollbar;

public class ItemList extends Sprite {
    private var gs:GameSprite;
    private var searchField_:TextInputField;
    private var searchItems:Vector.<MemMarketItem>;
    private var searchBackground:Sprite;
    private var searchScroll:Scrollbar;
    private var shape_:Shape;

    private static const SEARCH_X_OFFSET:int = 10;
    private static const SEARCH_Y_OFFSET:int = 10;
    private static const SEARCH_ITEM_SIZE:int = 50;
    private static const PADDING:int = 6;
    private static const SCROLLBAR_WIDTH:int = 10;

    public function ItemList(gs:GameSprite) {
        this.gs = gs;
        this.searchItems = new Vector.<MemMarketItem>();
        this.searchBackground = new Sprite();
        this.initUI();
    }

    private function initUI():void {
        // Suchfeld
        this.searchField_ = new TextInputField("", false, "", "", 210);
        this.searchField_.x = SEARCH_X_OFFSET + 4;
        this.searchField_.y = SEARCH_Y_OFFSET + 20;
        addChild(this.searchField_);

        // Hintergrund für die Item-Liste
        this.shape_ = new Shape();
        this.shape_.graphics.beginFill(0x000000); // Hintergrundfarbe
        this.shape_.graphics.drawRect(SEARCH_X_OFFSET, SEARCH_Y_OFFSET + 40, 250, 400); // +40 um Platz für das Suchfeld zu schaffen
        this.shape_.graphics.endFill();
        addChild(this.shape_);
        addChild(this.searchBackground);

        // Scrollbar hinzufügen
        this.searchScroll = new Scrollbar(10,400);
        this.searchScroll.x = SEARCH_X_OFFSET + 250 - SCROLLBAR_WIDTH; // Positioniere die Scrollbar rechts
        this.searchScroll.y = SEARCH_Y_OFFSET + 40; // Unter dem Suchfeld
        addChild(this.searchScroll);

        // Items suchen
        this.searchItemsFunc();
    }

    private function searchItemsFunc():void {
        this.clearPreviousResults();

        var index:int = 0;
        for each (var w:String in ObjectLibrary.typeToIdItems_) {
            if (GeneralUtils.isBanned(ObjectLibrary.idToTypeItems_[w]) || ObjectLibrary.idToTypeItems_[w] == null) {
                continue;
            }

            var item:MemMarketItem = new MemMarketItem(this.gs, SEARCH_ITEM_SIZE, SEARCH_ITEM_SIZE, 80, ObjectLibrary.idToTypeItems_[w], null);
            item.x = SEARCH_X_OFFSET + 1 + (SEARCH_ITEM_SIZE + PADDING) * (index % 4);
            item.y = SEARCH_Y_OFFSET + 41 + (SEARCH_ITEM_SIZE + PADDING) * int(index / 4); // +41 um Platz für das Suchfeld zu schaffen
            item.addEventListener(MouseEvent.CLICK, this.onItemClick);
            this.searchItems.push(item);
            index++;
        }

        for each (var x:MemMarketItem in this.searchItems) {
            this.searchBackground.addChild(x);
        }
    }

    private function clearPreviousResults():void {
        for each (var o:MemMarketItem in this.searchItems) {
            o.removeEventListener(MouseEvent.CLICK, this.onItemClick);
            o.dispose();
            this.searchBackground.removeChild(o);
            o = null;
        }
        this.searchItems.length = 0;
    }

    private function onItemClick(event:MouseEvent):void {
        var item:MemMarketItem = event.currentTarget as MemMarketItem;
        var itemName:String = ObjectLibrary.typeToDisplayId_[item.itemType_];
        this.gs.gsc_.playerText("/give " + itemName); // Befehl zum Geben des Items
    }
}
}
