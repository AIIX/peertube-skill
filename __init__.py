import json
import timeago, datetime
import dateutil.parser
import peertube
from youtube_dl import YoutubeDL
from peertube.rest import ApiException
from mycroft.skills.core import MycroftSkill, intent_handler, intent_file_handler
from mycroft.messagebus.message import Message
from mycroft.util.log import LOG
from xdg import XDG_CACHE_HOME, XDG_DATA_HOME
from json_database import JsonStorage

__author__ = 'aix'

class PeerTubeSkill(MycroftSkill):
    def __init__(self): 
        super(PeerTubeSkill, self).__init__(name="PeerTubeSkill")
        self.default_host = "https://peertube.co.uk/api/v1"
        self.configured_host = None
        cache_path = str(XDG_CACHE_HOME.absolute())
        if cache_path:
            self.peer_instance_config = JsonStorage(cache_path + "/peertube-instance-config.conf")
        else:
            self.peer_instance_config = JsonStorage(str(self.root_dir).rsplit("/", 1)[0] + "peertube-instance-config.conf")


        if "model" in self.peer_instance_config:
            self.peer_instance_host = self.peer_instance_config["model"]
            self.configured_host = self.peer_instance_config["model"]["hosturl"]
        else:
            self.peer_instance_host = None

        if self.configured_host is not None:
            self.peer_config = peertube.Configuration(
                host = self.configured_host)
        else:
            self.peer_config = peertube.Configuration(
                host = self.default_host)
        
        self.api_client = peertube.ApiClient(configuration=self.peer_config)
        self.search_instance = peertube.SearchApi(self.api_client)
        self.video_instance = peertube.VideoApi(self.api_client)
            
    def initialize(self):
        self.bus.on('peertube-skill.aiix.home', self.display_homepage)
        self.gui.register_handler('PeerTube.SearchQuery', self.search_page_query)
        self.gui.register_handler('PeerTube.WatchVideo', self.watch_video_via_query)
        self.gui.register_handler('PeerTube.SettingsPage', self.peer_settings_page)
        self.gui.register_handler('PeerTube.ConfigureHost', self.peer_configure_host)
    
    @intent_file_handler("PtOpenApp.intent")
    def display_homepage(self, message): 
        self.gui.clear()
        self.gui.show_page("PeerTubeLoading.qml", override_idle=True, override_animations=True)
        self.build_categories()
    
    def search_videos(self, query):
        # Global search for queries with PT api
        # JSONIFY return results
        try:
            search_pt = self.search_instance.search_videos_get(query)
            search_response = json.loads(json.dumps(search_pt.to_dict(), default=self.dt_converter))
            return search_response

        except ApiException as e:
            self.speak_dialog("Search.Failed", data={'query': message.data.get("search_query")})
    
    def search_page_query(self, message):
        # Receive query from GUI and return results for search
        user_query = message.data.get("search_query")
        get_response = self.search_videos(user_query)
        self.gui["search_results"] = get_response
        self.gui["search_completed"] = True
        
    def build_categories(self):
        # 1: Music, 2: Films, 3: Vehicles, 4: Art, 5: Sports, 6: Travels, 7: Gaming, 8: People, 
        # 9: Comedy, 10: Entertainment, 11: News & Politics, 12: How To, 13: Education, 14: Activism, 
        # 15: Science & Technology
        
        try:
            # Build only five categories
            news_category_list = self.video_instance.videos_get(category_one_of=11, count=10)
            music_category_list = self.video_instance.videos_get(category_one_of=1, count=10)
            entertainment_category_list = self.video_instance.videos_get(category_one_of=10, count=10)
            technology_category_list = self.video_instance.videos_get(category_one_of=15, count=10)
            gaming_category_list = self.video_instance.videos_get(category_one_of=7, count=10)
            
            LOG.info(json.dumps(news_category_list.to_dict(), default=self.dt_converter))
            
            self.gui["news_category_list"] = json.loads(json.dumps(news_category_list.to_dict(), default=self.dt_converter))
            self.gui["music_category_list"] = json.loads(json.dumps(music_category_list.to_dict(), default=self.dt_converter))
            self.gui["entertainment_category_list"] = json.loads(json.dumps(entertainment_category_list.to_dict(), default=self.dt_converter))
            self.gui["technology_category_list"] = json.loads(json.dumps(technology_category_list.to_dict(), default=self.dt_converter))
            self.gui["gaming_category_list"] = json.loads(json.dumps(gaming_category_list.to_dict(), default=self.dt_converter))
            self.gui["search_results"] = ""
            self.gui["search_completed"] = True
            
            self.gui.remove_page("PeerTubeLoading.qml")
            self.gui.show_page("PeerTubeHomePage.qml", override_idle=True, override_animations=True)
            
        except ApiException as e:
            self.gui.show_page("PeerTubeErrorPage.qml")
            self.speak_dialog("build_category_failed")
    
    def watch_video_via_query(self, message):
        # Event invoked by interaction on homepage video tiles 
        # We already have all the video listing data required
        video_idx0_host = message.data["account"]["host"]
        video_idx0_embed = message.data["embed_path"]
        video_embed_link = "https://" + video_idx0_host + video_idx0_embed
        try:
            # First run get static video url via youtube-dl as pt video api is unstable
            video_stream_link = self.process_stream(video_embed_link)
            if video_stream_link == False:
                # Try getting the static link manually from embedded object
                video_stream_link = str("https://" + video_idx0_host + "/static/webseed/" 
                                        + message.data["uuid"] + "-480.mp4")

        except ApiException as e:
            self.speak_dialog("search_failed")

        self.gui["video_meta"] = message.data
        self.gui["video_stream"] = video_stream_link
        self.gui["video_status"] = "play"
        self.gui.show_page("PeerTubePlayer.qml", override_idle=True, override_animations=True)
    
    @intent_file_handler("PtVoiceQuery.intent")
    def watch_video_via_voice(self, message):
        # Event invoked via voice query, triggered from anywhere
        # We don't have the video listing data required
        user_query = message.data['query']
        print(user_query)
        videos_matched = self.search_videos(user_query)
        print(videos_matched)
        video_idx0_host = videos_matched['data'][0]["account"]["host"]
        video_idx0_embed = videos_matched['data'][0]["embed_path"]
        video_embed_link = "https://" + video_idx0_host + video_idx0_embed
        try:
            # First run get static video url via youtube-dl as pt video api is unstable
            video_stream_link = self.process_stream(video_embed_link)
            if video_stream_link == False:
                # Try getting the static link manually from embedded object
                video_stream_link = str("https://" + video_idx0_host + "/static/webseed/" 
                                        + videos_matched['data'][0]["uuid"] + "-480.mp4")
            
        except ApiException as e:
            self.speak_dialog("search_failed")

        self.gui["video_meta"] = videos_matched['data'][0]
        self.gui["video_stream"] = video_stream_link
        self.gui["video_status"] = "play"
        self.gui.show_page("PeerTubePlayer.qml", override_idle=True, override_animations=True)
        
    def peer_settings_page(self, message):
        if message.data.get("settings_open") == True:
            if self.configured_host is not None:
                self.gui["current_instance"] = self.configured_host
            else:
                self.gui["current_instance"] = self.default_host

            instance_local_model = self.list_instances()
            self.gui["instances_model"] = instance_local_model
            gen_idx = []
            for x in range(len(instance_local_model)):
                gen_idx.append(instance_local_model[x]["hosturl"])

            self.gui["instance_string_model"] = gen_idx
            self.gui.show_page("PeerTubeSettings.qml", override_idle=True, override_animations=True)
        elif message.data.get("settings_open") == False:
            self.gui.remove_page("PeerTubeSettings.qml")
        
    def peer_configure_host(self, message):
        new_instance = message.data.get('selected_instance')
        self.peer_instance_config["model"] = {"hosturl": new_instance}
        self.peer_instance_config.store()
        self.configured_host = new_instance
        self.peer_config = peertube.Configuration(
            host = self.configured_host)
        self.api_client = peertube.ApiClient(configuration=self.peer_config)
        self.search_instance = peertube.SearchApi(self.api_client)
        self.video_instance = peertube.VideoApi(self.api_client)
        self.clean_built_models()
        
    def process_stream(self, embedded_url):
        # First round of processing to extract video stream 
        ydl = YoutubeDL()
        try:
            ydl_results = ydl.extract_info(embedded_url, download=False)
            return ydl_results['url']
        except:
            return False
        
    def dt_converter(self, o):
        if isinstance(o, datetime.datetime):
            return o.__str__()
        
    def list_instances(self):
        instance_listing = [
            {"hostname": "Peertube UK Instance", "hosturl": "https://peertube.co.uk/api/v1"},
            {"hostname": "Peertube Austrian Instance", "hosturl": "https://peertube.at/api/v1"},
            {"hostname": "Peertube Scandinavian Instance", "hosturl": "https://peertube.dk/api/v1"},
            {"hostname": "Peertube European Instance", "hosturl": "https://peertube.be/api/v1"},
            {"hostname": "Peertube Italian Instance", "hosturl": "https://peertube.uno/api/v1"}
        ]
        return instance_listing
        
    def clean_built_models(self):
        self.gui["news_category_list"] = ""
        self.gui["music_category_list"] = ""
        self.gui["entertainment_category_list"] = ""
        self.gui["technology_category_list"] = ""
        self.gui["gaming_category_list"] = ""
        self.gui["search_results"] = ""
        self.gui["search_completed"] = True
        self.display_homepage({})
    
def create_skill():
    return PeerTubeSkill()
