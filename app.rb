require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'open-uri'
require 'nokogiri'
require 'kconv'
require 'cgi'
require './models/druginfo.rb'


helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end


get '/' do
  @druginfo = Druginfo.all
  @categories = Category.all
  erb :index
end

post '/create' do
  Druginfo.create({
    name: params[:name],
    url: params[:url],
    category_id: params[:category]
  })
  redirect '/'
end

post '/delete/:id' do
    Druginfo.find(params[:id]).destroy

    redirect '/'
end

get '/category/:id' do
  @categories = Category.all
  @category = Category.find(params[:id])
  @category_name = @category.name
  @druginfo = @category.druginfos
  erb :index
end

post '/mining/:id' do
  @druginfo = Druginfo.find(params[:id])
  erb :mining
end

post '/search/:id' do
    @druginfo = Druginfo.find(params[:id])
    puts "----------------------------------------------"
    puts @druginfo.url
    @name = params[:sideeffect]
    page_number = 0
    parsed_html = []
    l = 0
    @sum_dose = 0
    page_n = 0

    loop{
      url = @druginfo.url + "#{page_n}"
      html = open(url).read
      parsed_html << Nokogiri::HTML.parse(html.toutf8, nil, 'UTF-8')
      parsed_html1 = Nokogiri::HTML.parse(html.toutf8, nil, 'UTF-8')
      parsed_html2 = parsed_html1.css("table" [2]).inner_text
      if parsed_html2.include?("発現日") then
        puts "処理開始"
      else
        puts "ループ終了"
        break
      end
      page_n = page_n + 1
    }

        i = 0
        # iは有害事象の報告件数
        m = 0
        # mは総報告件数

        men = 0
        # 男性の数
        women = 0
        # 女性の数
        other = 0
        @age = Array.new
        @dose = Array.new
        @time = Array.new
        @start_time = Array.new
        @end_time = Array.new
        @dosing_period = Array.new
        @weight = Array.new
        @height = Array.new
        @sideeffect = Array.new
        @s_effect = Array.new
        @aftercure = Array.new
        @sick = Array.new


    parsed_html.each do |parsed_html1|
        parsed_html1.css('table').each do |node|
            node2 = node.css('tr[7] td[2]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
            # 副作用総数の算出
            @sideeffect << node.css('tr[7] td[2]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
            side = node.css('tr[7] td[2]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
            side2 = side.gsub(/(\(.+?\))/,"")
            @s_effect += side2.split(" ")
            # puts "---------------------------------------------------"
            # 医薬品名検索
            @drug_name = node.css('tr[6] td[1]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")

                # 総数の算出
                if node2.include?("")
                    m = m + 1
                end

                if node2.include?(params[:sideeffect])
                    # 性別の分類わけ
                    if node.css('tr[3] td[2]').inner_text.include?('男')
                        men = men + 1
                        @sex = '男'
                        # puts node.css('tr[2] td[2]').inner_text
                    elsif node.css('tr[3] td[2]').inner_text.include?('女')
                        women = women + 1
                        @sex = '女'
                    else
                        other = other + 1
                        @sex = '不明'
                    end

                    # 年齢分け
                    @age << node.css('tr[3] td[4]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    # age = node.css('tr[2] td[4]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    # 投与量
                    @dose <<  node.css('tr[6] td[2]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    # dose = node.css('tr[5] td[2]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    # 報告時期
                    @time << node.css('tr[2] td[2]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")

                    # 投与開始 日数の算出
                    start_time = node.css('tr[6] td[3]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    start_time = start_time.split(//)
                    if start_time.length == 8
                        start_day =  (start_time[0].to_i*1000+start_time[1].to_i*100+start_time[2].to_i*10+start_time[3].to_i)*365+(start_time[4].to_i*10+start_time[5].to_i)*30+start_time[6].to_i*10+start_time[7].to_i
                    elsif start_time.length == 6
                        start_day =  (start_time[0].to_i*1000+start_time[1].to_i*100+start_time[2].to_i*10+start_time[3].to_i)*365+(start_time[4].to_i*10+start_time[5].to_i)*30
                    else
                        start_day = 0
                    end
                    # @start_time << node.css('tr[5] td[4]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")

                    # 投与終了 日数の算出
                    end_time = node.css('tr[6] td[4]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    end_time = end_time.split(//)
                    if end_time.length == 8
                        end_day =  (end_time[0].to_i*1000+end_time[1].to_i*100+end_time[2].to_i*10+end_time[3].to_i)*365+(end_time[4].to_i*10+end_time[5].to_i)*30+end_time[6].to_i*10+end_time[7].to_i
                    elsif end_time.length == 6
                        end_day =  (end_time[0].to_i*1000+end_time[1].to_i*100+end_time[2].to_i*10+end_time[3].to_i)*365+(end_time[4].to_i*10+end_time[5].to_i)*30
                    else
                        end_day = 0
                    end
                    # @end_time << node.css('tr[5] td[6]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    # 投与期間の算出
                    puts end_day
                    puts start_day
                    dosing_period = end_day - start_day
                    if dosing_period < 1
                        dosing_period = "不明"
                    elsif dosing_period > 730000
                        dosing_period = "開始時期不明"
                    else
                        @sum_dose = @sum_dose + dosing_period
                        l = l + 1
                    end
                    @dosing_period << dosing_period

                    # 体重
                    @weight << node.css('tr[3] td[8]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    # weight = node.css('tr[2] td[8]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    # 伸長
                    @height << node.css('tr[3] td[6]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    # height = node.css('tr[2] td[6]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                    # 転機
                    @aftercure << node.css('tr[3] td[10]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")

                    # 原発疾患
                     sick = node.css('tr[4] td[2]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")
                     sick2 = sick.gsub(/(\(.+?\))/,"")
                     @sick += sick2.split(" ")
                    # 有害事象と報告研修の算_出
                    # @sideeffect << node.css('tr[7] td[2]').inner_text.gsub(/(\r\n|\r|\n|\t)/, "")

                    i = i + 1
                else
                end
            # Attribute.create(sex: @sex,age: age,height: height,weight: weight,dosing_period: dosing_period,drug_name: @drug_name)
        end
    end

        # 年齢ハッシュの作成
        ages = @age.uniq
        number_of_age = Array.new
        ages.each do |age|
            number_of_age << @age.count(age)
        end
        age_ary = [ages,number_of_age].transpose
        @age_hash = Hash[*age_ary.flatten].sort

        # 投与量のハッシュの作成
        doses = @dose.uniq
        number_of_dose = Array.new
        doses.each do |dose|
            number_of_dose << @dose.count(dose)
        end
        dose_ary = [doses,number_of_dose].transpose
        @dose_hash =Hash[*dose_ary.flatten].sort

        # 報告時期のハッシュの作成
        times = @time.uniq
        number_of_time = Array.new
        times.each do |time|
            number_of_time << @time.count(time)
        end
        time_ary = [times,number_of_time].transpose
        @time_hash =Hash[*time_ary.flatten].sort

        # 体重のハッシュの作成
        weightes = @weight.uniq
        number_of_weight = Array.new
        weightes.each do |weight|
            number_of_weight << @weight.count(weight)
        end
        weight_ary = [weightes,number_of_weight].transpose
        @weight_hash =Hash[*weight_ary.flatten].sort

        # 身長のハッシュの作成
        heightes = @height.uniq
        number_of_height = Array.new
        heightes.each do |height|
            number_of_height << @height.count(height)
        end
        height_ary = [heightes,number_of_height].transpose
        @height_hash =Hash[*height_ary.flatten].sort

        # 有害事象のハッシュ作成
        sideeffectes = @sideeffect.uniq
        number_of_sideeffect = Array.new
        sideeffectes.each do |sideeffect|
            number_of_sideeffect << @sideeffect.count(sideeffect)
        end
        sideeffect_ary = [sideeffectes,number_of_sideeffect].transpose
        @sideeffect_hash =Hash[*sideeffect_ary.flatten].sort

        # 有害事象の頻度ハッシュ作成
        s_effectes = @s_effect.uniq
        number_of_s_effect = Array.new
        s_effectes.each do |s_effect|
            number_of_s_effect << @s_effect.count(s_effect)
        end
        s_effect_ary = [number_of_s_effect,s_effectes].transpose
        @s_effect_hash = s_effect_ary.sort.reverse

        # 転機の頻度ハッシュ作成
        aftercures = @aftercure.uniq
        number_of_aftercure = Array.new
        aftercures.each do |aftercure|
            number_of_aftercure << @aftercure.count(aftercure)
        end
        aftercure_ary = [number_of_aftercure,aftercures].transpose
        @aftercure_hash = aftercure_ary.sort.reverse
        # 原発疾患の頻度ハッシュ作成
        sicks = @sick.uniq
        number_of_sick = Array.new
        sicks.each do |sick|
            number_of_sick << @sick.count(sick)
        end
        sick_ary = [number_of_sick,sicks].transpose
        @sick_hash = sick_ary.sort.reverse

        puts "総報告数　#{i}"
        puts "総数　#{m}"
        @number_of_report = i
        @total_report = m - 4*page_n
        @men = men
        @women = women
        @other = other
        # 総数は１０４件出てくる。ページ数×4が余分な量となっている。

        puts l
        @l = l
        erb :mining
    end
