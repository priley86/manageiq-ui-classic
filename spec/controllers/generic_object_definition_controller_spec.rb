describe GenericObjectDefinitionController do
  include CompressedIds

  let!(:server) { EvmSpecHelper.local_miq_server(:zone => zone) }
  let(:zone) { FactoryGirl.build(:zone) }

  describe "#show" do
    render_views
    before(:each) do
      EvmSpecHelper.create_guid_miq_server_zone
      login_as FactoryGirl.create(:user)
    end

    it "should redirect to #show_list" do
      generic_obj_defn = FactoryGirl.create(:generic_object_definition)
      get :show, :params => {:id => generic_obj_defn.id}
      expect(response.status).to eq(302)
      expect(response).to redirect_to(:action => 'show_list')
      expect(controller.x_node).to eq("god-#{to_cid(generic_obj_defn.id)}")
    end

    context "#show when display=main" do
      before do
        allow_any_instance_of(GenericObjectDefinition).to receive(:generic_objects)
      end
      it "show the generic_object_definition record when display=main" do
        generic_obj_defn = FactoryGirl.create(:generic_object_definition)
        get :show, :params => {:id => generic_obj_defn.id, :display => "main"}
        expect(response.status).to eq(200)
      end
    end

    context "#show when @display=generic_objects" do
      it "renders the generic objects list" do
        generic_obj_defn = FactoryGirl.create(:generic_object_definition)
        FactoryGirl.create(:generic_object, :generic_object_definition_id => generic_obj_defn.id)
        controller.instance_variable_set(:@display, 'generic_objects')
        controller.instance_variable_set(:@breadcrumbs, [])
        controller.instance_variable_set(:@settings, {})
        params = {:id => generic_obj_defn.id, :type => 'grid'}
        allow(controller).to receive(:params).and_return(params)
        controller.send(:show)
        expect(controller.instance_variable_get(:@gtl_type)).to eq('grid')
        expect(response.status).to eq(200)
      end
    end
  end

  describe "#show_list" do
    before(:each) do
      stub_user(:features => :all)
      FactoryGirl.create(:generic_object_definition)
      allow(controller).to receive(:build_tree)
      allow(controller).to receive(:exp_build_table)
      get :show_list
    end
    it { expect(response.status).to eq(200) }
  end

  context "#button" do
    render_views

    before(:each) do
      stub_user(:features => :all)
      EvmSpecHelper.create_guid_miq_server_zone
      ApplicationController.handle_exceptions = true
      allow(controller).to receive(:build_tree)
    end

    it "when Generic Object Tag is pressed for the generic object nested list" do
      definition = FactoryGirl.create(:generic_object_definition)
      go = FactoryGirl.create(:generic_object, :generic_object_definition_id => definition.id)
      get :show, :params => {:id => definition.id, :display => 'generic_objects'}
      post :button, :params => {:pressed => "generic_object_tag", "check_#{go.id}" => "1", :id => definition.id, :display => 'generic_objects', :format => :js}
      expect(response.status).to eq(200)
      expect(response.body).to include('generic_object_definition/tagging_edit')
    end
  end

  context "#process_root_node" do
    before do
      EvmSpecHelper.create_guid_miq_server_zone
      login_as FactoryGirl.create(:user)
    end

    it "renders the toolbar for 'show_list'" do
      presenter = ExplorerPresenter.new(:active_tree => 'generic_object_definition_tree')
      toolbar_array = controller.send(:process_root_node, presenter)
      expect(toolbar_array[0][0][:id]).to eq('view_grid')
      expect(toolbar_array[0][0][:url]).to eq('/show_list')

      expect(toolbar_array[0][1][:id]).to eq('view_tile')
      expect(toolbar_array[0][1][:url]).to eq('/show_list')

      expect(toolbar_array[0][2][:id]).to eq('view_list')
      expect(toolbar_array[0][2][:url]).to eq('/show_list')
    end
  end

  context "Render form/Toolbar" do
    render_views

    before do
      stub_user(:features => :all)
      EvmSpecHelper.create_guid_miq_server_zone
      ApplicationController.handle_exceptions = true
      allow(controller).to receive(:build_tree)
    end

    it "does not display toolbar and paging div when custom button is edited" do
      custom_button = FactoryGirl.create(:custom_button,
                                         :applies_to_class => "GenericObjectDefinition",
                                         :name             => "Default",
                                         :options          => {
                                           'button_icon'  => 'ff ff-view-expanded',
                                           'button_color' => '#4727ff',
                                           'display'      => true,
                                         },)

      allow(controller).to receive(:x_node) { "cb-#{custom_button.id}" }
      post :tree_select, :params => {'id' => "cb-#{custom_button.id}"}

      post :custom_button_edit, :params => {:id => custom_button.id, :format => :js}
      expect(response.status).to eq(200)
      expect(response.body).to include('"setVisibility":{"paging_div":false,"toolbar":false}')
    end
  end
end
